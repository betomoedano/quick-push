//
//  FCMFileManager.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation
import AppKit

/// Manages selection and persistent storage of the Firebase service account JSON.
///
/// We read the file contents once when selected and store them directly in
/// UserDefaults (service account JSON is ~3–5 KB, well within limits).
class FCMFileManager {
  static let shared = FCMFileManager()

  private let contentsKey = "fcm_serviceAccountContents"
  private let filenameKey = "fcm_serviceAccountFilename"
  private let projectIdKey = "fcm_projectId"
  private let clientEmailKey = "fcm_clientEmail"

  // MARK: - File Picker

  enum SelectionError: Error {
    case notServiceAccount
    case unreadable

    var localizedDescription: String {
      switch self {
      case .notServiceAccount:
        return "This looks like a google-services.json (client config), not a service account key. Go to Firebase Console → Project Settings → Service Accounts → Generate new private key to get the correct file."
      case .unreadable:
        return "Could not read the selected file."
      }
    }
  }

  func selectServiceAccountFile(completion: @escaping (Result<(contents: String, filename: String, projectId: String?, clientEmail: String?), SelectionError>) -> Void) {
    let panel = NSOpenPanel()
    panel.title = "Select Firebase Service Account JSON"
    panel.allowedContentTypes = [.json]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false

    panel.begin { response in
      guard response == .OK, let url = panel.url else { return }

      guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
        completion(.failure(.unreadable))
        return
      }

      // Validate this is a service account file, not google-services.json
      guard Self.parsePrivateKey(from: contents) != nil else {
        completion(.failure(.notServiceAccount))
        return
      }

      let filename = url.lastPathComponent
      let (projectId, clientEmail) = Self.parse(serviceAccountContents: contents)

      self.save(contents: contents, filename: filename, projectId: projectId ?? "", clientEmail: clientEmail ?? "")
      completion(.success((contents, filename, projectId, clientEmail)))
    }
  }

  // MARK: - Parsing

  static func parse(serviceAccountContents: String) -> (projectId: String?, clientEmail: String?) {
    guard let data = serviceAccountContents.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return (nil, nil)
    }
    let projectId = json["project_id"] as? String
    let clientEmail = json["client_email"] as? String
    return (projectId, clientEmail)
  }

  static func parsePrivateKey(from serviceAccountContents: String) -> String? {
    guard let data = serviceAccountContents.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return nil
    }
    return json["private_key"] as? String
  }

  // MARK: - Storage

  func save(contents: String, filename: String, projectId: String, clientEmail: String) {
    UserDefaults.standard.set(contents, forKey: contentsKey)
    UserDefaults.standard.set(filename, forKey: filenameKey)
    UserDefaults.standard.set(projectId, forKey: projectIdKey)
    UserDefaults.standard.set(clientEmail, forKey: clientEmailKey)
  }

  func storedContents() -> String? {
    UserDefaults.standard.string(forKey: contentsKey)
  }

  func storedFilename() -> String? {
    UserDefaults.standard.string(forKey: filenameKey)
  }

  func storedProjectId() -> String? {
    UserDefaults.standard.string(forKey: projectIdKey)
  }

  func storedClientEmail() -> String? {
    UserDefaults.standard.string(forKey: clientEmailKey)
  }

  func clearStored() {
    UserDefaults.standard.removeObject(forKey: contentsKey)
    UserDefaults.standard.removeObject(forKey: filenameKey)
    UserDefaults.standard.removeObject(forKey: projectIdKey)
    UserDefaults.standard.removeObject(forKey: clientEmailKey)
  }
}
