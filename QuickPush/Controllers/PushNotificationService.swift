//
//  PushNotificationService.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import Foundation

class PushNotificationService {
  static let shared = PushNotificationService() // Singleton instance
  
  private let expoPushEndpoint = "https://exp.host/--/api/v2/push/send"
  
  /// Result containing the decoded response, HTTP status code, and raw JSON string.
  struct SendResult {
    let response: PushResponse
    let httpStatusCode: Int?
    let rawJSON: String?
  }

  func sendPushNotification(notification: PushNotification, accessToken: String? = nil, completion: @escaping (Result<SendResult, Error>) -> Void) {
    guard let url = URL(string: expoPushEndpoint) else {
      completion(.failure(APIError.invalidURL))
      return
    }

    // Prepare request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("exp.host", forHTTPHeaderField: "host")
    request.setValue("application/json", forHTTPHeaderField: "accept")
    request.setValue("gzip, deflate", forHTTPHeaderField: "accept-encoding")
    request.setValue("application/json", forHTTPHeaderField: "content-type")

    // Add authorization header if access token is provided
    if let accessToken = accessToken, !accessToken.isEmpty {
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    do {
      let jsonData = try JSONEncoder().encode(notification)
      request.httpBody = jsonData
    } catch {
      completion(.failure(APIError.encodingFailed))
      return
    }

    // Perform network request
    URLSession.shared.dataTask(with: request) { data, response, error in
      // Handle network errors
      if let error = error {
        completion(.failure(error))
        return
      }

      let httpStatusCode = (response as? HTTPURLResponse)?.statusCode

      // Ensure we have valid data
      guard let data = data else {
        completion(.failure(APIError.noData))
        return
      }

      let rawJSON = Self.prettyPrint(data)

      // Decode API response
      do {
        let responseObject = try JSONDecoder().decode(PushResponse.self, from: data)

        // UNAUTHORIZED REQUESTS CHECK - Possibly no Access Token
        if let errors = responseObject.errors,
           errors.contains(where: { $0.code == "UNAUTHORIZED" }) {
          completion(.failure(APIError.insufficientPermissions))
          return
        }

        completion(.success(SendResult(response: responseObject, httpStatusCode: httpStatusCode, rawJSON: rawJSON)))
      } catch {
        completion(.failure(APIError.decodingFailed))
      }
    }.resume()
  }

  /// Pretty-print raw JSON data for display.
  private static func prettyPrint(_ data: Data) -> String? {
    guard let json = try? JSONSerialization.jsonObject(with: data),
          let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
      return String(data: data, encoding: .utf8)
    }
    return String(data: pretty, encoding: .utf8)
  }
}

// MARK: - API Error Enum
enum APIError: Error, LocalizedError {
  case invalidURL
  case encodingFailed
  case noData
  case decodingFailed
  case insufficientPermissions
  
  var errorDescription: String? {
    switch self {
    case .invalidURL: return "Invalid API URL"
    case .encodingFailed: return "Failed to encode request data"
    case .noData: return "No response data received"
    case .decodingFailed: return "Failed to decode API response"
    case .insufficientPermissions: return "Insufficient permissions. Push security may be enabled for this app - please provide a valid access token above."
    }
  }
}
