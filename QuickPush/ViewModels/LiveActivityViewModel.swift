//
//  LiveActivityViewModel.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

@Observable
class LiveActivityViewModel {
  // MARK: - Event Type
  var eventType: LiveActivityEvent = .start

  // MARK: - Token
  var deviceToken: String = ""

  // MARK: - Content State
  var contentTitle: String = ""
  var contentSubtitle: String = ""
  var includeProgress: Bool = false
  var progress: Double = 0.5
  var includeTimerEnd: Bool = false
  var timerEndDate: Date = Date().addingTimeInterval(3600)
  var includeElapsedTimer: Bool = false
  var elapsedTimerStartDate: Date = Date()
  var imageName: String = ""
  var dynamicIslandImageName: String = ""

  // MARK: - Attributes (Start only)
  var attributeName: String = ""
  var backgroundColor: Color = Color(hex: "001A72")
  var titleColor: Color = Color(hex: "EBEBF0")
  var subtitleColor: Color = Color(hex: "EBEBF599")
  var progressTintColor: Color = Color(hex: "FFFFFF")
  var progressLabelColor: Color = Color(hex: "EBEBF0")
  var deepLinkURL: String = ""
  var timerType: String = "digital"
  var imagePosition: String = "left"
  var imageWidth: Double = 40
  var imageHeight: Double = 40
  var useCustomPadding: Bool = false
  var uniformPadding: Int = 16
  var paddingHorizontal: Int = 20
  var paddingTop: Int = 16
  var paddingBottom: Int = 16

  // MARK: - Alert (Start only)
  var includeAlert: Bool = false
  var alertTitle: String = ""
  var alertBody: String = ""
  var alertSound: String = "default"

  // MARK: - APNs Configuration
  var teamId: String = "" {
    didSet { UserDefaults.standard.set(teamId, forKey: "apns_teamId") }
  }
  var keyId: String = "" {
    didSet { UserDefaults.standard.set(keyId, forKey: "apns_keyId") }
  }
  var bundleId: String = "" {
    didSet { UserDefaults.standard.set(bundleId, forKey: "apns_bundleId") }
  }
  var p8FileURL: URL? {
    didSet { if let url = p8FileURL { SecurityBookmarkManager.shared.saveBookmark(for: url) } }
  }
  var environment: APNsEnvironment = .sandbox {
    didSet { UserDefaults.standard.set(environment.rawValue, forKey: "apns_environment") }
  }

  // MARK: - UI State
  var isSending: Bool = false
  var showToast: Bool = false
  var toastMessage: String = ""
  var toastType: ToastType = .success
  var showJSONSheet: Bool = false

  // MARK: - Init
  init() {
    teamId = UserDefaults.standard.string(forKey: "apns_teamId") ?? ""
    keyId = UserDefaults.standard.string(forKey: "apns_keyId") ?? ""
    bundleId = UserDefaults.standard.string(forKey: "apns_bundleId") ?? ""
    p8FileURL = SecurityBookmarkManager.shared.resolveBookmark()
    if let envString = UserDefaults.standard.string(forKey: "apns_environment"),
       let env = APNsEnvironment(rawValue: envString) {
      environment = env
    }
  }

  // MARK: - Validation
  var canSend: Bool {
    !deviceToken.isEmpty && apnsConfiguration.isValid && !isSending
  }

  var apnsConfiguration: APNsConfiguration {
    APNsConfiguration(
      teamId: teamId,
      keyId: keyId,
      bundleId: bundleId,
      p8FileURL: p8FileURL,
      environment: environment
    )
  }

  var tokenLabel: String {
    eventType == .start ? "Push-to-Start Token" : "Activity Token"
  }

  // MARK: - Build Payload
  func buildPayload() -> LiveActivityAPNsPayload {
    let contentState = LiveActivityContentState(
      title: contentTitle.isEmpty ? nil : contentTitle,
      subtitle: contentSubtitle.isEmpty ? nil : contentSubtitle,
      progress: includeProgress ? progress : nil,
      timerEndDateInMilliseconds: includeTimerEnd ? Int(timerEndDate.timeIntervalSince1970 * 1000) : nil,
      elapsedTimerStartDateInMilliseconds: includeElapsedTimer ? Int(elapsedTimerStartDate.timeIntervalSince1970 * 1000) : nil,
      imageName: imageName.isEmpty ? nil : imageName,
      dynamicIslandImageName: dynamicIslandImageName.isEmpty ? nil : dynamicIslandImageName
    )

    var attributes: LiveActivityAttributes?
    if eventType == .start {
      let padding: LiveActivityPadding?
      if useCustomPadding {
        padding = .custom(horizontal: paddingHorizontal, top: paddingTop, bottom: paddingBottom)
      } else {
        padding = .uniform(uniformPadding)
      }

      let imgSize: LiveActivityImageSize?
      if !imageName.isEmpty || !dynamicIslandImageName.isEmpty {
        imgSize = LiveActivityImageSize(width: imageWidth, height: imageHeight)
      } else {
        imgSize = nil
      }

      attributes = LiveActivityAttributes(
        name: attributeName.isEmpty ? nil : attributeName,
        backgroundColor: backgroundColor.toHexString(),
        titleColor: titleColor.toHexString(),
        subtitleColor: subtitleColor.toHexStringWithAlpha(),
        progressTintColor: progressTintColor.toHexString(),
        progressLabelColor: progressLabelColor.toHexString(),
        deepLinkURL: deepLinkURL.isEmpty ? nil : deepLinkURL,
        timerType: timerType,
        imagePosition: imagePosition,
        imageSize: imgSize,
        padding: padding
      )
    }

    var alert: LiveActivityAlert?
    if includeAlert && eventType == .start {
      alert = LiveActivityAlert(
        title: alertTitle.isEmpty ? nil : alertTitle,
        body: alertBody.isEmpty ? nil : alertBody,
        sound: alertSound.isEmpty ? nil : alertSound
      )
    }

    let aps = LiveActivityAPS(
      timestamp: Int(Date().timeIntervalSince1970 * 1000),
      event: eventType,
      contentState: contentState,
      attributesType: eventType == .start ? "ExpoLiveActivityAttributes" : nil,
      attributes: attributes,
      alert: alert,
      dismissalDate: eventType == .end ? Int(Date().addingTimeInterval(5).timeIntervalSince1970) : nil,
      relevanceScore: nil,
      staleDate: nil
    )

    return LiveActivityAPNsPayload(aps: aps)
  }

  // MARK: - Send
  func send() {
    guard canSend else { return }
    isSending = true

    let payload = buildPayload()

    APNsService.shared.sendLiveActivityPush(
      payload: payload,
      token: deviceToken,
      configuration: apnsConfiguration
    ) { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        self.isSending = false
        switch result {
        case .success(let message):
          self.showToastMessage(message, type: .success)
        case .failure(let error):
          self.showToastMessage(error.localizedDescription, type: .error)
        }
      }
    }
  }

  // MARK: - JSON Export/Import
  func exportJSON() -> String {
    let payload = buildPayload()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    guard let data = try? encoder.encode(payload),
          let json = String(data: data, encoding: .utf8) else {
      return "{}"
    }
    return json
  }

  func importJSON(_ jsonString: String) -> Bool {
    guard let data = jsonString.data(using: .utf8) else { return false }

    do {
      let payload = try JSONDecoder().decode(LiveActivityAPNsPayload.self, from: data)
      applyPayload(payload)
      return true
    } catch {
      showToastMessage("Invalid JSON: \(error.localizedDescription)", type: .error)
      return false
    }
  }

  private func applyPayload(_ payload: LiveActivityAPNsPayload) {
    let aps = payload.aps
    eventType = aps.event

    // Content State
    let cs = aps.contentState
    contentTitle = cs.title ?? ""
    contentSubtitle = cs.subtitle ?? ""
    if let p = cs.progress {
      includeProgress = true
      progress = p
    } else {
      includeProgress = false
    }
    if let timerEnd = cs.timerEndDateInMilliseconds {
      includeTimerEnd = true
      timerEndDate = Date(timeIntervalSince1970: Double(timerEnd) / 1000)
    } else {
      includeTimerEnd = false
    }
    if let elapsed = cs.elapsedTimerStartDateInMilliseconds {
      includeElapsedTimer = true
      elapsedTimerStartDate = Date(timeIntervalSince1970: Double(elapsed) / 1000)
    } else {
      includeElapsedTimer = false
    }
    imageName = cs.imageName ?? ""
    dynamicIslandImageName = cs.dynamicIslandImageName ?? ""

    // Attributes
    if let attrs = aps.attributes {
      attributeName = attrs.name ?? ""
      if let bg = attrs.backgroundColor { backgroundColor = Color(hex: bg) }
      if let tc = attrs.titleColor { titleColor = Color(hex: tc) }
      if let sc = attrs.subtitleColor { subtitleColor = Color(hex: sc) }
      if let pt = attrs.progressTintColor { progressTintColor = Color(hex: pt) }
      if let pl = attrs.progressLabelColor { progressLabelColor = Color(hex: pl) }
      deepLinkURL = attrs.deepLinkURL ?? ""
      timerType = attrs.timerType ?? "digital"
      imagePosition = attrs.imagePosition ?? "left"
      if let size = attrs.imageSize {
        imageWidth = size.width
        imageHeight = size.height
      }
      if let padding = attrs.padding {
        switch padding {
        case .uniform(let value):
          useCustomPadding = false
          uniformPadding = value
        case .custom(let h, let t, let b):
          useCustomPadding = true
          paddingHorizontal = h
          paddingTop = t
          paddingBottom = b
        }
      }
    }

    // Alert
    if let alert = aps.alert {
      includeAlert = true
      alertTitle = alert.title ?? ""
      alertBody = alert.body ?? ""
      alertSound = alert.sound ?? "default"
    } else {
      includeAlert = false
    }
  }

  // MARK: - Toast
  private func showToastMessage(_ message: String, type: ToastType) {
    toastMessage = message
    toastType = type
    showToast = true
  }

  // MARK: - File Picker
  func selectP8File() {
    SecurityBookmarkManager.shared.selectP8File { [weak self] url in
      DispatchQueue.main.async {
        self?.p8FileURL = url
      }
    }
  }

  // MARK: - Clipboard
  func pasteToken() {
    if let clipboardString = NSPasteboard.general.string(forType: .string) {
      let trimmed = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
      let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
      if trimmed.unicodeScalars.allSatisfy({ hexCharacterSet.contains($0) }) && !trimmed.isEmpty {
        deviceToken = trimmed
      } else {
        showToastMessage("Invalid token format. Expected hex string.", type: .error)
      }
    }
  }
}
