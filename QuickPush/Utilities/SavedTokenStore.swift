//
//  SavedTokenStore.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation

/// Manages persistent storage of saved Expo push tokens in UserDefaults.
class SavedTokenStore {
  static let shared = SavedTokenStore()

  private let storageKey = "savedPushTokens"

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
