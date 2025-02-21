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
  
  func sendPushNotification(notification: PushNotification, completion: @escaping (Result<PushResponse, Error>) -> Void) {
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
      
      // Ensure we have valid data
      guard let data = data else {
        completion(.failure(APIError.noData))
        return
      }
      
      // Decode API response
      do {
        let responseObject = try JSONDecoder().decode(PushResponse.self, from: data)
        completion(.success(responseObject))
      } catch {
        completion(.failure(APIError.decodingFailed))
      }
    }.resume()
  }
}

// MARK: - API Error Enum
enum APIError: Error, LocalizedError {
  case invalidURL
  case encodingFailed
  case noData
  case decodingFailed
  
  var errorDescription: String? {
    switch self {
    case .invalidURL: return "Invalid API URL"
    case .encodingFailed: return "Failed to encode request data"
    case .noData: return "No response data received"
    case .decodingFailed: return "Failed to decode API response"
    }
  }
}
