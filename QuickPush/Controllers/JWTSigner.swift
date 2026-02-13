//
//  JWTSigner.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import Foundation
import CryptoKit

class JWTSigner {
  enum JWTError: Error, LocalizedError {
    case invalidP8File
    case signingFailed
    case invalidKeyData

    var errorDescription: String? {
      switch self {
      case .invalidP8File: return "Invalid .p8 key file"
      case .signingFailed: return "Failed to sign JWT token"
      case .invalidKeyData: return "Invalid key data in .p8 file"
      }
    }
  }

  static func generateToken(teamId: String, keyId: String, p8Contents: String) throws -> String {
    let privateKey = try parseP8Key(p8Contents)

    let header = [
      "alg": "ES256",
      "kid": keyId,
      "typ": "JWT"
    ]

    let now = Int(Date().timeIntervalSince1970)
    let claims: [String: Any] = [
      "iss": teamId,
      "iat": now
    ]

    let headerData = try JSONSerialization.data(withJSONObject: header)
    let claimsData = try JSONSerialization.data(withJSONObject: claims)

    let headerBase64 = base64urlEncode(headerData)
    let claimsBase64 = base64urlEncode(claimsData)

    let signingInput = "\(headerBase64).\(claimsBase64)"
    guard let signingData = signingInput.data(using: .utf8) else {
      throw JWTError.signingFailed
    }

    let signature = try privateKey.signature(for: signingData)
    let signatureBase64 = base64urlEncode(signature.rawRepresentation)

    return "\(signingInput).\(signatureBase64)"
  }

  private static func parseP8Key(_ p8Contents: String) throws -> P256.Signing.PrivateKey {
    let lines = p8Contents.components(separatedBy: "\n")
    let keyLines = lines.filter { line in
      !line.hasPrefix("-----") && !line.isEmpty
    }
    let base64Key = keyLines.joined()

    guard let keyData = Data(base64Encoded: base64Key) else {
      throw JWTError.invalidKeyData
    }

    do {
      return try P256.Signing.PrivateKey(derRepresentation: keyData)
    } catch {
      throw JWTError.invalidP8File
    }
  }

  private static func base64urlEncode(_ data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
