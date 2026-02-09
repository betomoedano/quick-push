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
  var imageName: String = ""
  var dynamicIslandImageName: String = ""

  // MARK: - Attributes (Start only)
  var attributeName: String = ""
  var backgroundColor: Color = Color(hex: "001A72")
  var titleColor: Color = Color(hex: "EBEBF0")
  var subtitleColor: Color = Color(hex: "EBEBF599")
  var progressViewTint: Color = Color(hex: "FFFFFF")
  var progressViewLabelColor: Color = Color(hex: "EBEBF0")
  var deepLinkUrl: String = ""
  var timerType: String = "digital"
  var imagePosition: String = "left"
  var imageWidth: Int = 40
  var imageHeight: Int = 40
  var useCustomPadding: Bool = false
  var uniformPadding: Int = 16
  var paddingTop: Int = 16
  var paddingBottom: Int = 16
  var paddingLeft: Int = 16
  var paddingRight: Int = 16

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
  /// Display name of the selected .p8 file (e.g. "AuthKey_ABC123.p8").
  var p8FileName: String?
  /// The raw contents of the .p8 key are stored in SecurityBookmarkManager
  /// and read on demand via `storedP8Contents()`. This flag tracks whether
  /// a key has been selected.
  var hasP8Key: Bool = false
  var attributesType: String = "LiveActivityAttributes" {
    didSet { UserDefaults.standard.set(attributesType, forKey: "apns_attributesType") }
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
  var showResponseSheet: Bool = false
  var lastResponse: APNsResponse?

  // MARK: - Init
  init() {
    teamId = UserDefaults.standard.string(forKey: "apns_teamId") ?? ""
    keyId = UserDefaults.standard.string(forKey: "apns_keyId") ?? ""
    bundleId = UserDefaults.standard.string(forKey: "apns_bundleId") ?? ""
    p8FileName = SecurityBookmarkManager.shared.storedP8Filename()
    hasP8Key = SecurityBookmarkManager.shared.storedP8Contents() != nil
    attributesType = UserDefaults.standard.string(forKey: "apns_attributesType") ?? "LiveActivityAttributes"
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
      p8Contents: SecurityBookmarkManager.shared.storedP8Contents(),
      environment: environment
    )
  }

  var tokenLabel: String {
    eventType == .start ? "Push-to-Start Token" : "Activity Token"
  }

  // MARK: - Build Payload
  func buildPayload() -> LiveActivityAPNsPayload {
    let contentState = LiveActivityContentState(
      title: contentTitle.isEmpty ? "Activity" : contentTitle,
      subtitle: contentSubtitle.isEmpty ? nil : contentSubtitle,
      timerEndDateInMilliseconds: includeTimerEnd ? timerEndDate.timeIntervalSince1970 * 1000 : nil,
      progress: includeProgress ? progress : nil,
      imageName: imageName.isEmpty ? nil : imageName,
      dynamicIslandImageName: dynamicIslandImageName.isEmpty ? nil : dynamicIslandImageName
    )

    var attributes: LiveActivityAttributes?
    if eventType == .start {
      let paddingDetails: LiveActivityPaddingDetails?
      if useCustomPadding {
        paddingDetails = LiveActivityPaddingDetails(
          top: paddingTop,
          bottom: paddingBottom,
          left: paddingLeft,
          right: paddingRight
        )
      } else {
        paddingDetails = nil
      }

      attributes = LiveActivityAttributes(
        name: attributeName.isEmpty ? "LiveActivity" : attributeName,
        backgroundColor: backgroundColor.toHexString(),
        titleColor: titleColor.toHexString(),
        subtitleColor: subtitleColor.toHexStringWithAlpha(),
        progressViewTint: progressViewTint.toHexString(),
        progressViewLabelColor: progressViewLabelColor.toHexString(),
        deepLinkUrl: deepLinkUrl.isEmpty ? nil : deepLinkUrl,
        timerType: timerType,
        padding: useCustomPadding ? nil : uniformPadding,
        paddingDetails: paddingDetails,
        imagePosition: imagePosition,
        imageWidth: (!imageName.isEmpty || !dynamicIslandImageName.isEmpty) ? imageWidth : nil,
        imageHeight: (!imageName.isEmpty || !dynamicIslandImageName.isEmpty) ? imageHeight : nil
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
      timestamp: Int(Date().addingTimeInterval(5).timeIntervalSince1970),
      event: eventType,
      contentState: contentState,
      attributesType: eventType == .start ? attributesType : nil,
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
        case .success(let response):
          self.lastResponse = response
          self.showToastMessage(response.summary, type: .success)
        case .failure(let error):
          if case APNsService.APNsError.requestFailed(let response) = error {
            self.lastResponse = response
          }
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
    contentTitle = cs.title
    contentSubtitle = cs.subtitle ?? ""
    if let p = cs.progress {
      includeProgress = true
      progress = p
    } else {
      includeProgress = false
    }
    if let timerEnd = cs.timerEndDateInMilliseconds {
      includeTimerEnd = true
      timerEndDate = Date(timeIntervalSince1970: timerEnd / 1000)
    } else {
      includeTimerEnd = false
    }
    imageName = cs.imageName ?? ""
    dynamicIslandImageName = cs.dynamicIslandImageName ?? ""

    // Attributes
    if let attrs = aps.attributes {
      attributeName = attrs.name
      if let bg = attrs.backgroundColor { backgroundColor = Color(hex: bg) }
      if let tc = attrs.titleColor { titleColor = Color(hex: tc) }
      if let sc = attrs.subtitleColor { subtitleColor = Color(hex: sc) }
      if let pt = attrs.progressViewTint { progressViewTint = Color(hex: pt) }
      if let pl = attrs.progressViewLabelColor { progressViewLabelColor = Color(hex: pl) }
      deepLinkUrl = attrs.deepLinkUrl ?? ""
      timerType = attrs.timerType ?? "digital"
      imagePosition = attrs.imagePosition ?? "left"
      if let w = attrs.imageWidth { imageWidth = w }
      if let h = attrs.imageHeight { imageHeight = h }
      if let p = attrs.padding {
        useCustomPadding = false
        uniformPadding = p
      }
      if let pd = attrs.paddingDetails {
        useCustomPadding = true
        paddingTop = pd.top ?? 16
        paddingBottom = pd.bottom ?? 16
        paddingLeft = pd.left ?? 16
        paddingRight = pd.right ?? 16
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
    SecurityBookmarkManager.shared.selectP8File { [weak self] contents, filename in
      DispatchQueue.main.async {
        guard let self else { return }
        self.p8FileName = filename
        self.hasP8Key = contents != nil
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
