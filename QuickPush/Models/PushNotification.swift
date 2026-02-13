//
//  PushNotification.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import Foundation

struct PushNotification: Codable {
  let to: [String]  // Supports both single and multiple recipients
  let title: String
  let body: String
  let data: [String: String]?
  let ttl: Int?
  let expiration: Int?
  let priority: Priority?
  let subtitle: String?
  let sound: String?
  let badge: Int?
  let interruptionLevel: InterruptionLevel?
  let channelId: String?
  let categoryId: String?
  let mutableContent: Bool?
  let contentAvailable: Bool?
  let richContent: RichContent?

  enum Priority: String, Codable {
    case `default`, normal, high
  }

  enum InterruptionLevel: String, Codable {
    case active, critical, passive, timeSensitive = "time-sensitive"
  }

  struct RichContent: Codable {
    let image: String
  }
  
  enum CodingKeys: String, CodingKey {
    case to, title, body, data, ttl, expiration, priority, subtitle, sound, badge
    case interruptionLevel = "interruptionLevel"
    case channelId = "channelId"
    case categoryId = "categoryId"
    case mutableContent = "mutableContent"
    case contentAvailable = "_contentAvailable"
    case richContent
  }
  
  init(
    to: [String],
    title: String,
    body: String,
    data: [String: String]? = nil,
    ttl: Int? = nil,
    expiration: Int? = nil,
    priority: Priority? = .default,
    subtitle: String? = nil,
    sound: String? = "default",
    badge: Int? = nil,
    interruptionLevel: InterruptionLevel? = nil,
    channelId: String? = nil,
    categoryId: String? = nil,
    mutableContent: Bool? = false,
    contentAvailable: Bool? = nil,
    richContent: RichContent? = nil
  ) {
    self.to = to
    self.title = title
    self.body = body
    self.data = data
    self.ttl = ttl
    self.expiration = expiration
    self.priority = priority
    self.subtitle = subtitle
    self.sound = sound
    self.badge = badge
    self.interruptionLevel = interruptionLevel
    self.channelId = channelId
    self.categoryId = categoryId
    self.mutableContent = mutableContent
    self.contentAvailable = contentAvailable
    self.richContent = richContent
  }
}
