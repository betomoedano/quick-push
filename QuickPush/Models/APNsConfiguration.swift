//
//  APNsConfiguration.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import Foundation

struct APNsConfiguration {
  var teamId: String = ""
  var keyId: String = ""
  var bundleId: String = ""
  var p8FileURL: URL?
  var environment: APNsEnvironment = .sandbox

  var isValid: Bool {
    !teamId.isEmpty && !keyId.isEmpty && !bundleId.isEmpty && p8FileURL != nil
  }

  var hostname: String {
    environment.hostname
  }

  var topic: String {
    "\(bundleId).push-type.liveactivity"
  }
}

enum APNsEnvironment: String, CaseIterable {
  case sandbox
  case production

  var hostname: String {
    switch self {
    case .sandbox: return "api.sandbox.push.apple.com"
    case .production: return "api.push.apple.com"
    }
  }
}
