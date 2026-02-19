//
//  FCMPayload.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import Foundation

struct FCMMessage: Encodable {
  var token: String
  var notification: FCMNotification?
  var android: FCMAndroidConfig?
  var data: [String: String]?

  enum CodingKeys: String, CodingKey {
    case token, notification, android, data
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(token, forKey: .token)
    try container.encodeIfPresent(notification, forKey: .notification)
    try container.encodeIfPresent(android, forKey: .android)
    if let data, !data.isEmpty {
      try container.encode(data, forKey: .data)
    }
  }
}

struct FCMNotification: Encodable {
  var title: String?
  var body: String?
  var image: String?

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(title, forKey: .title)
    try container.encodeIfPresent(body, forKey: .body)
    try container.encodeIfPresent(image, forKey: .image)
  }

  enum CodingKeys: String, CodingKey {
    case title, body, image
  }
}

struct FCMAndroidConfig: Encodable {
  var priority: String = "HIGH"
  var notification: FCMAndroidNotification?

  enum CodingKeys: String, CodingKey {
    case priority, notification
  }
}

struct FCMAndroidNotification: Encodable {
  var channelId: String?
  var sound: String?
  var color: String?

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(channelId, forKey: .channelId)
    try container.encodeIfPresent(sound, forKey: .sound)
    try container.encodeIfPresent(color, forKey: .color)
  }

  enum CodingKeys: String, CodingKey {
    case channelId = "channel_id"
    case sound
    case color
  }
}

struct FCMRequestBody: Encodable {
  var message: FCMMessage
}
