//
//  LiveActivityPayload.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import Foundation

struct LiveActivityAPNsPayload: Codable {
  let aps: LiveActivityAPS

  enum CodingKeys: String, CodingKey {
    case aps
  }
}

struct LiveActivityAPS: Codable {
  let timestamp: Int
  let event: LiveActivityEvent
  let contentState: LiveActivityContentState
  let attributesType: String?
  let attributes: LiveActivityAttributes?
  let alert: LiveActivityAlert?
  let dismissalDate: Int?
  let relevanceScore: Double?
  let staleDate: Int?

  enum CodingKeys: String, CodingKey {
    case timestamp, event
    case contentState = "content-state"
    case attributesType = "attributes-type"
    case attributes, alert
    case dismissalDate = "dismissal-date"
    case relevanceScore = "relevance-score"
    case staleDate = "stale-date"
  }
}

enum LiveActivityEvent: String, Codable, CaseIterable {
  case start
  case update
  case end
}

struct LiveActivityContentState: Codable {
  var title: String?
  var subtitle: String?
  var progress: Double?
  var timerEndDateInMilliseconds: Int?
  var elapsedTimerStartDateInMilliseconds: Int?
  var imageName: String?
  var dynamicIslandImageName: String?
}

struct LiveActivityAttributes: Codable {
  var name: String?
  var backgroundColor: String?
  var titleColor: String?
  var subtitleColor: String?
  var progressTintColor: String?
  var progressLabelColor: String?
  var deepLinkURL: String?
  var timerType: String?
  var imagePosition: String?
  var imageSize: LiveActivityImageSize?
  var padding: LiveActivityPadding?
}

struct LiveActivityImageSize: Codable {
  var width: Double
  var height: Double
}

enum LiveActivityPadding: Codable {
  case uniform(Int)
  case custom(horizontal: Int, top: Int, bottom: Int)

  enum CodingKeys: String, CodingKey {
    case horizontal, top, bottom
  }

  init(from decoder: Decoder) throws {
    if let container = try? decoder.singleValueContainer(),
       let value = try? container.decode(Int.self) {
      self = .uniform(value)
      return
    }

    let container = try decoder.container(keyedBy: CodingKeys.self)
    let horizontal = try container.decode(Int.self, forKey: .horizontal)
    let top = try container.decode(Int.self, forKey: .top)
    let bottom = try container.decode(Int.self, forKey: .bottom)
    self = .custom(horizontal: horizontal, top: top, bottom: bottom)
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .uniform(let value):
      var container = encoder.singleValueContainer()
      try container.encode(value)
    case .custom(let horizontal, let top, let bottom):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(horizontal, forKey: .horizontal)
      try container.encode(top, forKey: .top)
      try container.encode(bottom, forKey: .bottom)
    }
  }
}

struct LiveActivityAlert: Codable {
  var title: String?
  var body: String?
  var sound: String?
}
