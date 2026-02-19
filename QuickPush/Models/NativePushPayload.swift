//
//  NativePushPayload.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation

enum NativePushType: String, CaseIterable {
  case alert
  case background
}

enum NativeInterruptionLevel: String, CaseIterable {
  case active
  case passive
  case timeSensitive = "time-sensitive"
  case critical

  var displayName: String {
    switch self {
    case .active: return "Active"
    case .passive: return "Passive"
    case .timeSensitive: return "Time Sensitive"
    case .critical: return "Critical"
    }
  }
}

struct NativeAlert: Codable {
  var title: String?
  var subtitle: String?
  var body: String?
}

struct NativeAPS: Encodable {
  var alert: NativeAlert?
  var badge: Int?
  var sound: String?
  var contentAvailable: Int?
  var mutableContent: Int?
  var threadId: String?
  var category: String?
  var interruptionLevel: String?

  enum CodingKeys: String, CodingKey {
    case alert
    case badge
    case sound
    case contentAvailable = "content-available"
    case mutableContent = "mutable-content"
    case threadId = "thread-id"
    case category
    case interruptionLevel = "interruption-level"
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(alert, forKey: .alert)
    try container.encodeIfPresent(badge, forKey: .badge)
    try container.encodeIfPresent(sound, forKey: .sound)
    try container.encodeIfPresent(contentAvailable, forKey: .contentAvailable)
    try container.encodeIfPresent(mutableContent, forKey: .mutableContent)
    try container.encodeIfPresent(threadId, forKey: .threadId)
    try container.encodeIfPresent(category, forKey: .category)
    try container.encodeIfPresent(interruptionLevel, forKey: .interruptionLevel)
  }
}

private struct RichBody: Encodable {
  struct RichContent: Encodable { let image: String }
  let _richContent: RichContent
  enum CodingKeys: String, CodingKey { case _richContent = "_richContent" }
}

struct NativePushPayload: Encodable {
  var aps: NativeAPS
  var customData: [String: String]
  var imageUrl: String?

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: DynamicCodingKey.self)
    try container.encode(aps, forKey: DynamicCodingKey(stringValue: "aps"))
    if let imageUrl, !imageUrl.isEmpty {
      let richBody = RichBody(_richContent: .init(image: imageUrl))
      try container.encode(richBody, forKey: DynamicCodingKey(stringValue: "body"))
    }
    for (key, value) in customData {
      try container.encode(value, forKey: DynamicCodingKey(stringValue: key))
    }
  }
}

private struct DynamicCodingKey: CodingKey {
  var stringValue: String
  init(stringValue: String) { self.stringValue = stringValue }
  var intValue: Int? { nil }
  init?(intValue: Int) { return nil }
}
