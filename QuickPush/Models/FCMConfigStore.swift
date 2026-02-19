//
//  FCMConfigStore.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation

/// Shared FCM credentials store used by the FCM tab.
@Observable
class FCMConfigStore {
  static let shared = FCMConfigStore()

  var projectId: String = "" {
    didSet { UserDefaults.standard.set(projectId, forKey: "fcm_projectId") }
  }
  var clientEmail: String = "" {
    didSet { UserDefaults.standard.set(clientEmail, forKey: "fcm_clientEmail") }
  }
  var serviceAccountFilename: String?
  var hasServiceAccount: Bool = false
  var fileError: String?

  init() {
    projectId = UserDefaults.standard.string(forKey: "fcm_projectId") ?? ""
    clientEmail = UserDefaults.standard.string(forKey: "fcm_clientEmail") ?? ""
    serviceAccountFilename = FCMFileManager.shared.storedFilename()
    hasServiceAccount = FCMFileManager.shared.storedContents() != nil
  }

  func selectServiceAccountFile() {
    FCMFileManager.shared.selectServiceAccountFile { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        switch result {
        case .success(let info):
          self.fileError = nil
          self.serviceAccountFilename = info.filename
          self.hasServiceAccount = true
          if let projectId = info.projectId, !projectId.isEmpty {
            self.projectId = projectId
          }
          if let clientEmail = info.clientEmail, !clientEmail.isEmpty {
            self.clientEmail = clientEmail
          }
        case .failure(let error):
          self.fileError = error.localizedDescription
        }
      }
    }
  }

  func fcmConfiguration() -> FCMConfiguration {
    FCMConfiguration(
      projectId: projectId,
      clientEmail: clientEmail,
      serviceAccountContents: FCMFileManager.shared.storedContents()
    )
  }
}
