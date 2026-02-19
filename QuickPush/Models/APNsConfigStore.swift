//
//  APNsConfigStore.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation

/// Shared APNs credentials store used by both the Live Activity and APNs tabs.
@Observable
class APNsConfigStore {
  static let shared = APNsConfigStore()

  var teamId: String = "" {
    didSet { UserDefaults.standard.set(teamId, forKey: "apns_teamId") }
  }
  var keyId: String = "" {
    didSet { UserDefaults.standard.set(keyId, forKey: "apns_keyId") }
  }
  var bundleId: String = "" {
    didSet { UserDefaults.standard.set(bundleId, forKey: "apns_bundleId") }
  }
  var p8FileName: String?
  var hasP8Key: Bool = false
  var environment: APNsEnvironment = .sandbox {
    didSet { UserDefaults.standard.set(environment.rawValue, forKey: "apns_environment") }
  }

  init() {
    teamId = UserDefaults.standard.string(forKey: "apns_teamId") ?? ""
    keyId = UserDefaults.standard.string(forKey: "apns_keyId") ?? ""
    bundleId = UserDefaults.standard.string(forKey: "apns_bundleId") ?? ""
    p8FileName = SecurityBookmarkManager.shared.storedP8Filename()
    hasP8Key = SecurityBookmarkManager.shared.storedP8Contents() != nil
    if let envString = UserDefaults.standard.string(forKey: "apns_environment"),
       let env = APNsEnvironment(rawValue: envString) {
      environment = env
    }
  }

  func selectP8File() {
    SecurityBookmarkManager.shared.selectP8File { [weak self] contents, filename in
      DispatchQueue.main.async {
        guard let self else { return }
        self.p8FileName = filename
        self.hasP8Key = contents != nil
      }
    }
  }

  /// Build an `APNsConfiguration` with an optional topic suffix appended to bundleId.
  /// - Parameter topicSuffix: e.g. `".push-type.liveactivity"` for Live Activity, `nil` for plain bundle ID.
  func apnsConfiguration(topicSuffix: String?) -> APNsConfiguration {
    let topicOverride: String? = topicSuffix.map { "\(bundleId)\($0)" }
    return APNsConfiguration(
      teamId: teamId,
      keyId: keyId,
      bundleId: bundleId,
      p8Contents: SecurityBookmarkManager.shared.storedP8Contents(),
      environment: environment,
      topicOverride: topicOverride
    )
  }
}
