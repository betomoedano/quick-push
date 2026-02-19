//
//  FCMService.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation
import Security

/// Full diagnostic info returned after every FCM request.
struct FCMResponse {
  let statusCode: Int
  let messageId: String?
  let errorCode: String?
  let errorMessage: String?
  let projectId: String
  let token: String
  let timestamp: Int

  var isSuccess: Bool { statusCode == 200 }

  var summary: String {
    if isSuccess {
      return "200 OK"
    } else {
      return "\(statusCode): \(errorCode ?? errorMessage ?? "Unknown")"
    }
  }

  var diagnosticDetails: String {
    var lines: [String] = []
    lines.append("Status:      \(statusCode) \(isSuccess ? "OK" : "Error")")
    if let messageId { lines.append("Message ID:  \(messageId)") }
    if let errorCode { lines.append("Error Code:  \(errorCode)") }
    if let errorMessage { lines.append("Error Msg:   \(errorMessage)") }
    lines.append("Project ID:  \(projectId)")
    lines.append("Token:       \(token.prefix(20))…")
    lines.append("Timestamp:   \(timestamp) (Unix seconds)")
    return lines.joined(separator: "\n")
  }
}

class FCMService {
  static let shared = FCMService()

  private var cachedAccessToken: String?
  private var tokenExpiresAt: Date?
  private let tokenLifetime: TimeInterval = 55 * 60 // 55 min (Google tokens valid 60 min)

  enum FCMError: Error, LocalizedError {
    case invalidConfiguration
    case cannotReadServiceAccount
    case invalidPrivateKey
    case signingFailed
    case oauthFailed(String)
    case requestFailed(response: FCMResponse)
    case networkError(String)

    var errorDescription: String? {
      switch self {
      case .invalidConfiguration:
        return "FCM configuration is incomplete. Please fill in all fields."
      case .cannotReadServiceAccount:
        return "Cannot read service account JSON. Please re-select the file."
      case .invalidPrivateKey:
        return "Invalid private key in service account JSON."
      case .signingFailed:
        return "Failed to sign OAuth JWT."
      case .oauthFailed(let msg):
        return "OAuth token exchange failed: \(msg)"
      case .requestFailed(let response):
        return "FCM error: \(response.summary)"
      case .networkError(let message):
        return "Network error: \(message)"
      }
    }
  }

  // MARK: - Send

  func send(
    message: FCMMessage,
    configuration: FCMConfiguration,
    completion: @escaping (Result<FCMResponse, Error>) -> Void
  ) {
    guard configuration.isValid else {
      completion(.failure(FCMError.invalidConfiguration))
      return
    }
    guard let serviceAccountContents = configuration.serviceAccountContents,
          !serviceAccountContents.isEmpty else {
      completion(.failure(FCMError.cannotReadServiceAccount))
      return
    }

    getOrRefreshAccessToken(serviceAccountContents: serviceAccountContents, clientEmail: configuration.clientEmail) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let accessToken):
        self.sendWithToken(
          accessToken: accessToken,
          message: message,
          projectId: configuration.projectId,
          completion: completion
        )
      }
    }
  }

  private func sendWithToken(
    accessToken: String,
    message: FCMMessage,
    projectId: String,
    completion: @escaping (Result<FCMResponse, Error>) -> Void
  ) {
    let urlString = "https://fcm.googleapis.com/v1/projects/\(projectId)/messages:send"
    guard let url = URL(string: urlString) else {
      completion(.failure(FCMError.networkError("Invalid FCM URL")))
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = FCMRequestBody(message: message)
    let encoder = JSONEncoder()
    do {
      request.httpBody = try encoder.encode(body)
    } catch {
      completion(.failure(error))
      return
    }

    let timestamp = Int(Date().timeIntervalSince1970)

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(FCMError.networkError(error.localizedDescription)))
        return
      }
      guard let httpResponse = response as? HTTPURLResponse else {
        completion(.failure(FCMError.networkError("Invalid response")))
        return
      }

      var messageId: String?
      var errorCode: String?
      var errorMessage: String?

      if let data = data,
         let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        messageId = json["name"] as? String
        if let errorObj = json["error"] as? [String: Any] {
          errorCode = errorObj["status"] as? String
          errorMessage = errorObj["message"] as? String
          // Also check nested details for FCM-specific error codes
          if errorCode == nil,
             let details = errorObj["details"] as? [[String: Any]] {
            for detail in details {
              if let code = detail["errorCode"] as? String {
                errorCode = code
                break
              }
            }
          }
        }
      }

      let fcmResponse = FCMResponse(
        statusCode: httpResponse.statusCode,
        messageId: messageId,
        errorCode: errorCode,
        errorMessage: errorMessage,
        projectId: projectId,
        token: message.token,
        timestamp: timestamp
      )

      if httpResponse.statusCode == 200 {
        completion(.success(fcmResponse))
      } else {
        completion(.failure(FCMError.requestFailed(response: fcmResponse)))
      }
    }.resume()
  }

  // MARK: - OAuth Token

  private func getOrRefreshAccessToken(
    serviceAccountContents: String,
    clientEmail: String,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    if let token = cachedAccessToken,
       let expiresAt = tokenExpiresAt,
       Date() < expiresAt {
      completion(.success(token))
      return
    }

    do {
      let jwt = try buildOAuthJWT(serviceAccountContents: serviceAccountContents, clientEmail: clientEmail)
      exchangeJWTForAccessToken(jwt: jwt, completion: { result in
        switch result {
        case .success(let token):
          self.cachedAccessToken = token
          self.tokenExpiresAt = Date().addingTimeInterval(self.tokenLifetime)
          completion(.success(token))
        case .failure(let error):
          completion(.failure(error))
        }
      })
    } catch {
      completion(.failure(error))
    }
  }

  private func exchangeJWTForAccessToken(
    jwt: String,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
      completion(.failure(FCMError.networkError("Invalid OAuth URL")))
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let body = "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=\(jwt)"
    request.httpBody = body.data(using: .utf8)

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(FCMError.oauthFailed(error.localizedDescription)))
        return
      }
      guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        completion(.failure(FCMError.oauthFailed("Invalid response")))
        return
      }
      if let token = json["access_token"] as? String {
        completion(.success(token))
      } else {
        let errDesc = (json["error_description"] as? String) ?? (json["error"] as? String) ?? "Unknown OAuth error"
        completion(.failure(FCMError.oauthFailed(errDesc)))
      }
    }.resume()
  }

  // MARK: - RS256 JWT for OAuth

  private func buildOAuthJWT(serviceAccountContents: String, clientEmail: String) throws -> String {
    guard let privateKeyPEM = FCMFileManager.parsePrivateKey(from: serviceAccountContents) else {
      throw FCMError.cannotReadServiceAccount
    }

    let privateKey = try loadRSAPrivateKey(pem: privateKeyPEM)

    let header = ["alg": "RS256", "typ": "JWT"]
    let now = Int(Date().timeIntervalSince1970)
    let claims: [String: Any] = [
      "iss": clientEmail,
      "sub": clientEmail,
      "aud": "https://oauth2.googleapis.com/token",
      "scope": "https://www.googleapis.com/auth/firebase.messaging",
      "iat": now,
      "exp": now + 3600
    ]

    let headerData = try JSONSerialization.data(withJSONObject: header)
    let claimsData = try JSONSerialization.data(withJSONObject: claims)

    let headerB64 = base64urlEncode(headerData)
    let claimsB64 = base64urlEncode(claimsData)
    let signingInput = "\(headerB64).\(claimsB64)"

    guard let signingData = signingInput.data(using: .utf8) else {
      throw FCMError.signingFailed
    }

    var error: Unmanaged<CFError>?
    guard let signatureData = SecKeyCreateSignature(
      privateKey,
      .rsaSignatureMessagePKCS1v15SHA256,
      signingData as CFData,
      &error
    ) as Data? else {
      throw FCMError.signingFailed
    }

    let signatureB64 = base64urlEncode(signatureData)
    return "\(signingInput).\(signatureB64)"
  }

  // MARK: - RSA Key Loading (PKCS#8 → PKCS#1)

  private func loadRSAPrivateKey(pem: String) throws -> SecKey {
    // Strip PEM headers and decode base64
    let lines = pem.components(separatedBy: "\n")
    let keyLines = lines.filter { !$0.hasPrefix("-----") && !$0.isEmpty }
    let base64Key = keyLines.joined()
    guard let pkcs8DER = Data(base64Encoded: base64Key) else {
      throw FCMError.invalidPrivateKey
    }

    // Google service accounts use PKCS#8 format. SecKey requires PKCS#1.
    // We must strip the PKCS#8 wrapper to get the inner PKCS#1 RSAPrivateKey.
    let pkcs1DER = try extractPKCS1FromPKCS8(pkcs8DER)

    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
      kSecAttrKeySizeInBits as String: 2048
    ]

    var error: Unmanaged<CFError>?
    guard let secKey = SecKeyCreateWithData(pkcs1DER as CFData, attributes as CFDictionary, &error) else {
      throw FCMError.invalidPrivateKey
    }
    return secKey
  }

  /// Strips the PKCS#8 AlgorithmIdentifier wrapper to extract the inner PKCS#1 RSAPrivateKey bytes.
  ///
  /// PKCS#8 DER layout:
  ///   SEQUENCE {
  ///     INTEGER (version = 0)
  ///     SEQUENCE { OID(rsaEncryption), NULL }   ← algorithm identifier
  ///     OCTET STRING { <PKCS#1 RSAPrivateKey> }
  ///   }
  private func extractPKCS1FromPKCS8(_ der: Data) throws -> Data {
    let bytes = Array(der)
    var index = 0

    // Helper to skip a DER length field and return the content length.
    func readLength() throws -> Int {
      guard index < bytes.count else { throw FCMError.invalidPrivateKey }
      if bytes[index] & 0x80 == 0 {
        let len = Int(bytes[index]); index += 1; return len
      }
      let numBytes = Int(bytes[index] & 0x7F); index += 1
      guard index + numBytes <= bytes.count else { throw FCMError.invalidPrivateKey }
      var len = 0
      for _ in 0..<numBytes { len = (len << 8) | Int(bytes[index]); index += 1 }
      return len
    }

    // Outer SEQUENCE
    guard index < bytes.count, bytes[index] == 0x30 else { throw FCMError.invalidPrivateKey }
    index += 1
    _ = try readLength() // skip outer SEQUENCE length

    // version INTEGER (0)
    guard index < bytes.count, bytes[index] == 0x02 else { throw FCMError.invalidPrivateKey }
    index += 1
    let versionLen = try readLength()
    index += versionLen

    // AlgorithmIdentifier SEQUENCE — skip it
    guard index < bytes.count, bytes[index] == 0x30 else { throw FCMError.invalidPrivateKey }
    index += 1
    let algoLen = try readLength()
    index += algoLen

    // OCTET STRING containing the PKCS#1 key
    guard index < bytes.count, bytes[index] == 0x04 else { throw FCMError.invalidPrivateKey }
    index += 1
    let octetLen = try readLength()

    guard index + octetLen <= bytes.count else { throw FCMError.invalidPrivateKey }
    return Data(bytes[index..<(index + octetLen)])
  }

  // MARK: - Helpers

  private func base64urlEncode(_ data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  func invalidateToken() {
    cachedAccessToken = nil
    tokenExpiresAt = nil
  }
}
