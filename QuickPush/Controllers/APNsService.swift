//
//  APNsService.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import Foundation

class APNsService {
  static let shared = APNsService()

  private var cachedToken: String?
  private var tokenGeneratedAt: Date?
  private let tokenLifetime: TimeInterval = 50 * 60 // 50 minutes (APNs allows 60)

  enum APNsError: Error, LocalizedError {
    case invalidConfiguration
    case cannotReadP8File
    case requestFailed(statusCode: Int, reason: String)
    case networkError(String)

    var errorDescription: String? {
      switch self {
      case .invalidConfiguration:
        return "APNs configuration is incomplete. Please fill in all fields."
      case .cannotReadP8File:
        return "Cannot read .p8 key file. Please re-select the file."
      case .requestFailed(let statusCode, let reason):
        return "APNs error (\(statusCode)): \(reason)"
      case .networkError(let message):
        return "Network error: \(message)"
      }
    }
  }

  func sendLiveActivityPush(
    payload: LiveActivityAPNsPayload,
    token: String,
    configuration: APNsConfiguration,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    guard configuration.isValid else {
      completion(.failure(APNsError.invalidConfiguration))
      return
    }

    guard let p8Contents = configuration.p8Contents, !p8Contents.isEmpty else {
      completion(.failure(APNsError.cannotReadP8File))
      return
    }

    let jwt: String
    do {
      jwt = try getOrRefreshToken(
        teamId: configuration.teamId,
        keyId: configuration.keyId,
        p8Contents: p8Contents
      )
    } catch {
      completion(.failure(error))
      return
    }

    let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
    let urlString = "https://\(configuration.hostname)/3/device/\(cleanToken)"
    guard let url = URL(string: urlString) else {
      completion(.failure(APNsError.networkError("Invalid URL")))
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("bearer \(jwt)", forHTTPHeaderField: "authorization")
    request.setValue(configuration.topic, forHTTPHeaderField: "apns-topic")
    request.setValue("liveactivity", forHTTPHeaderField: "apns-push-type")
    request.setValue("10", forHTTPHeaderField: "apns-priority")
    request.setValue("application/json", forHTTPHeaderField: "content-type")

    do {
      let encoder = JSONEncoder()
      request.httpBody = try encoder.encode(payload)
    } catch {
      completion(.failure(error))
      return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(APNsError.networkError(error.localizedDescription)))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        completion(.failure(APNsError.networkError("Invalid response")))
        return
      }

      if httpResponse.statusCode == 200 {
        completion(.success("Live Activity push sent successfully!"))
      } else {
        var reason = "Unknown error"
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let r = json["reason"] as? String {
          reason = r
        }
        completion(.failure(APNsError.requestFailed(statusCode: httpResponse.statusCode, reason: reason)))
      }
    }.resume()
  }

  private func getOrRefreshToken(teamId: String, keyId: String, p8Contents: String) throws -> String {
    if let cached = cachedToken,
       let generatedAt = tokenGeneratedAt,
       Date().timeIntervalSince(generatedAt) < tokenLifetime {
      return cached
    }

    let token = try JWTSigner.generateToken(teamId: teamId, keyId: keyId, p8Contents: p8Contents)
    cachedToken = token
    tokenGeneratedAt = Date()
    return token
  }

  func invalidateToken() {
    cachedToken = nil
    tokenGeneratedAt = nil
  }
}
