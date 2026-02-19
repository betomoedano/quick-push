//
//  SavedTokenStore.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation

/// Manages persistent storage of saved push tokens in UserDefaults.
class SavedTokenStore {
  /// Store for Expo push tokens (ExponentPushToken format).
  static let shared = SavedTokenStore()
  /// Store for native APNs device tokens (hex format).
  static let nativePush = SavedTokenStore(storageKey: "savedNativePushTokens")
  /// Store for FCM registration tokens.
  static let fcm = SavedTokenStore(storageKey: "savedFCMTokens")

  private let storageKey: String

  init(storageKey: String = "savedPushTokens") {
    self.storageKey = storageKey
  }

  // MARK: - Read

  func loadTokens() -> [SavedToken] {
    guard let data = UserDefaults.standard.data(forKey: storageKey) else {
      return []
    }
    return (try? JSONDecoder().decode([SavedToken].self, from: data)) ?? []
  }

  // MARK: - Write

  func saveTokens(_ tokens: [SavedToken]) {
    if let data = try? JSONEncoder().encode(tokens) {
      UserDefaults.standard.set(data, forKey: storageKey)
    }
  }

  func addToken(_ token: SavedToken) {
    var tokens = loadTokens()
    tokens.append(token)
    saveTokens(tokens)
  }

  func removeToken(id: UUID) {
    var tokens = loadTokens()
    tokens.removeAll { $0.id == id }
    saveTokens(tokens)
  }
}
