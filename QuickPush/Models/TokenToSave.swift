//
//  TokenToSave.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation

/// Identifiable wrapper for the `.sheet(item:)` token-save presentation.
struct TokenToSave: Identifiable {
  let id = UUID()
  let index: Int
  let token: String
}
