//
//  NativePushViewModel.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

@Observable
class NativePushViewModel {
  // MARK: - Shared APNs config
  var config: APNsConfigStore = .shared

  // MARK: - Token
  var deviceToken: String = ""
  var savedTokens: [SavedToken] = []

  // MARK: - Push fields
  var pushType: NativePushType = .alert
  var title: String = ""
  var subtitle: String = ""
  var body: String = ""
  var sound: String = "default"
  var badge: String = ""
  var threadId: String = ""
  var categoryId: String = ""
  var interruptionLevel: NativeInterruptionLevel = .active
  var imageUrl: String = ""
  var mutableContent: Bool = false
  var contentAvailable: Bool = false
  var priority: Int = 10
  var customData: [String: String] = [:]

  // MARK: - UI State
  var isSending: Bool = false
  var showToast: Bool = false
  var toastMessage: String = ""
  var toastType: ToastType = .success
  var showResponseSheet: Bool = false
  var showCurlSheet: Bool = false
  var lastResponse: APNsResponse?
  var tokenToSave: TokenToSave?
  var curlCommand: String = ""

  // MARK: - Init
  init() {
    savedTokens = SavedTokenStore.nativePush.loadTokens()
  }

  // MARK: - Validation
  var canSend: Bool {
    !deviceToken.isEmpty && config.apnsConfiguration(topicSuffix: nil).isValid && !isSending
  }

  // MARK: - Build Payload
  func buildPayload() -> NativePushPayload {
    var alert: NativeAlert?
    if pushType == .alert {
      alert = NativeAlert(
        title: title.isEmpty ? nil : title,
        subtitle: subtitle.isEmpty ? nil : subtitle,
        body: body.isEmpty ? nil : body
      )
    }

    let effectiveMutableContent = mutableContent || !imageUrl.isEmpty
    let aps = NativeAPS(
      alert: alert,
      badge: Int(badge),
      sound: (pushType == .alert && !sound.isEmpty) ? sound : nil,
      contentAvailable: contentAvailable ? 1 : nil,
      mutableContent: effectiveMutableContent ? 1 : nil,
      threadId: threadId.isEmpty ? nil : threadId,
      category: categoryId.isEmpty ? nil : categoryId,
      interruptionLevel: (pushType == .alert) ? interruptionLevel.rawValue : nil
    )

    return NativePushPayload(aps: aps, customData: customData, imageUrl: imageUrl.isEmpty ? nil : imageUrl)
  }

  // MARK: - Send
  func send() {
    guard canSend else { return }
    isSending = true

    let payload = buildPayload()
    let configuration = config.apnsConfiguration(topicSuffix: nil)

    APNsService.shared.sendNativePush(
      payload: payload,
      token: deviceToken,
      pushType: pushType,
      priority: priority,
      configuration: configuration
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

  // MARK: - cURL
  func generateCurlCommand() -> String {
    let configuration = config.apnsConfiguration(topicSuffix: nil)
    let jwt: String
    if let p8Contents = configuration.p8Contents,
       let token = try? JWTSigner.generateToken(
         teamId: configuration.teamId,
         keyId: configuration.keyId,
         p8Contents: p8Contents
       ) {
      jwt = token
    } else {
      jwt = "<JWT>"
    }

    let cleanToken = deviceToken.trimmingCharacters(in: .whitespacesAndNewlines)
    let payload = buildPayload()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let bodyString: String
    if let data = try? encoder.encode(payload),
       let str = String(data: data, encoding: .utf8) {
      bodyString = str
    } else {
      bodyString = "{}"
    }

    var lines: [String] = []
    lines.append("# Note: JWT tokens expire after 1 hour.")
    lines.append("curl --http2 -X POST \\")
    lines.append("  https://\(configuration.hostname)/3/device/\(cleanToken) \\")
    lines.append("  -H \"authorization: bearer \(jwt)\" \\")
    lines.append("  -H \"apns-topic: \(configuration.topic)\" \\")
    lines.append("  -H \"apns-push-type: \(pushType.rawValue)\" \\")
    lines.append("  -H \"apns-priority: \(priority)\" \\")
    lines.append("  -H \"content-type: application/json\" \\")
    lines.append("  -d '\(bodyString)'")

    return lines.joined(separator: "\n")
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

  // MARK: - Toast
  func showToastMessage(_ message: String, type: ToastType) {
    toastMessage = message
    toastType = type
    showToast = true
  }
}
