//
//  SavedToken.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation

struct SavedToken: Codable, Identifiable, Equatable {
  let id: UUID
  var label: String
  var token: String
  var isEnabled: Bool

  init(id: UUID = UUID(), label: String, token: String, isEnabled: Bool = true) {
    self.id = id
    self.label = label
    self.token = token
    self.isEnabled = isEnabled
  }
}
