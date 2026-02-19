//
//  APNsService.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import Foundation

/// Full diagnostic info returned after every APNs request.
struct APNsResponse {
  let statusCode: Int
  let reason: String?
  let apnsId: String?
  let apnsUniqueId: String?
  let environment: APNsEnvironment
  let topic: String
  let timestamp: Int
  let hostname: String
  let attributesType: String?
  let event: String

  var isSuccess: Bool { statusCode == 200 }

  /// Short summary shown in the toast.
  var summary: String {
    let envLabel = environment.rawValue.capitalized
    if isSuccess {
      return "200 OK (\(envLabel))"
    } else {
      return "\(statusCode): \(reason ?? "Unknown") (\(envLabel))"
    }
  }

  /// Multi-line diagnostic block for the detail view.
  var diagnosticDetails: String {
    var lines: [String] = []
    lines.append("Status:         \(statusCode) \(isSuccess ? "OK" : "Error")")
    if let reason { lines.append("Reason:         \(reason)") }
    lines.append("Environment:    \(environment.rawValue.capitalized) (\(hostname))")
    lines.append("Topic:          \(topic)")
    lines.append("Event:          \(event)")
    if let attributesType { lines.append("Attributes Type: \(attributesType)") }
    lines.append("Timestamp:      \(timestamp) (Unix seconds)")
    if let apnsId { lines.append("apns-id:        \(apnsId)") }
    if let apnsUniqueId { lines.append("apns-unique-id: \(apnsUniqueId)") }
    return lines.joined(separator: "\n")
  }
}

class APNsService {
  static let shared = APNsService()

  private var cachedToken: String?
  private var tokenGeneratedAt: Date?
  private let tokenLifetime: TimeInterval = 50 * 60 // 50 minutes (APNs allows 60)

  enum APNsError: Error, LocalizedError {
    case invalidConfiguration
    case cannotReadP8File
    case requestFailed(response: APNsResponse)
    case networkError(String)

    var errorDescription: String? {
      switch self {
      case .invalidConfiguration:
        return "APNs configuration is incomplete. Please fill in all fields."
      case .cannotReadP8File:
        return "Cannot read .p8 key file. Please re-select the file."
      case .requestFailed(let response):
        return "APNs error: \(response.summary)"
      case .networkError(let message):
        return "Network error: \(message)"
      }
    }
  }

  func sendLiveActivityPush(
    payload: LiveActivityAPNsPayload,
    token: String,
    configuration: APNsConfiguration,
    completion: @escaping (Result<APNsResponse, Error>) -> Void
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

    let payloadTimestamp = payload.aps.timestamp

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

      let apnsId = httpResponse.value(forHTTPHeaderField: "apns-id")
      let apnsUniqueId = httpResponse.value(forHTTPHeaderField: "apns-unique-id")

      var reason: String?
      if let data = data,
         let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
         let r = json["reason"] as? String {
        reason = r
      }

      let apnsResponse = APNsResponse(
        statusCode: httpResponse.statusCode,
        reason: reason,
        apnsId: apnsId,
        apnsUniqueId: apnsUniqueId,
        environment: configuration.environment,
        topic: configuration.topic,
        timestamp: payloadTimestamp,
        hostname: configuration.hostname,
        attributesType: payload.aps.attributesType,
        event: payload.aps.event.rawValue
      )

      if httpResponse.statusCode == 200 {
        completion(.success(apnsResponse))
      } else {
        completion(.failure(APNsError.requestFailed(response: apnsResponse)))
      }
    }.resume()
  }

  func sendNativePush(
    payload: NativePushPayload,
    token: String,
    pushType: NativePushType,
    priority: Int,
    configuration: APNsConfiguration,
    completion: @escaping (Result<APNsResponse, Error>) -> Void
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
    request.setValue(pushType.rawValue, forHTTPHeaderField: "apns-push-type")
    request.setValue(String(priority), forHTTPHeaderField: "apns-priority")
    request.setValue("application/json", forHTTPHeaderField: "content-type")

    let timestamp = Int(Date().timeIntervalSince1970)

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

      let apnsId = httpResponse.value(forHTTPHeaderField: "apns-id")
      let apnsUniqueId = httpResponse.value(forHTTPHeaderField: "apns-unique-id")

      var reason: String?
      if let data = data,
         let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
         let r = json["reason"] as? String {
        reason = r
      }

      let apnsResponse = APNsResponse(
        statusCode: httpResponse.statusCode,
        reason: reason,
        apnsId: apnsId,
        apnsUniqueId: apnsUniqueId,
        environment: configuration.environment,
        topic: configuration.topic,
        timestamp: timestamp,
        hostname: configuration.hostname,
        attributesType: nil,
        event: pushType.rawValue
      )

      if httpResponse.statusCode == 200 {
        completion(.success(apnsResponse))
      } else {
        completion(.failure(APNsError.requestFailed(response: apnsResponse)))
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
