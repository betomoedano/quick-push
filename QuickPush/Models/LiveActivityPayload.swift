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

// Matches ExpoLiveActivityAttributes.ContentState exactly
struct LiveActivityContentState: Codable {
  var title: String
  var subtitle: String?
  var timerEndDateInMilliseconds: Double?
  var progress: Double?
  var imageName: String?
  var dynamicIslandImageName: String?
}

// Matches ExpoLiveActivityAttributes exactly
struct LiveActivityAttributes: Codable {
  var name: String
  var backgroundColor: String?
  var titleColor: String?
  var subtitleColor: String?
  var progressViewTint: String?
  var progressViewLabelColor: String?
  var deepLinkUrl: String?
  var timerType: String?
  var padding: Int?
  var paddingDetails: LiveActivityPaddingDetails?
  var imagePosition: String?
  var imageWidth: Int?
  var imageHeight: Int?
}

struct LiveActivityPaddingDetails: Codable {
  var top: Int?
  var bottom: Int?
  var left: Int?
  var right: Int?
  var vertical: Int?
  var horizontal: Int?
}

struct LiveActivityAlert: Codable {
  var title: String?
  var body: String?
  var sound: String?
}
