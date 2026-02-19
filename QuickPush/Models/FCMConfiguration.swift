//
//  FCMConfiguration.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation

struct FCMConfiguration {
  var projectId: String = ""
  var clientEmail: String = ""
  var serviceAccountContents: String?

  var isValid: Bool {
    !projectId.isEmpty && !clientEmail.isEmpty &&
    serviceAccountContents != nil && !serviceAccountContents!.isEmpty
  }
}

enum FCMMessageType: String, CaseIterable {
  case notification = "Notification"
  case data = "Data"
}
