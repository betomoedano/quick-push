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

  // MARK: - Tokens
  var tokens: [String] = [""]
  var savedTokens: [SavedToken] = []

  var allValidTokens: [String] {
    savedTokens.filter(\.isEnabled).map(\.token) + tokens.filter { !$0.isEmpty }
  }

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
    !allValidTokens.isEmpty && config.apnsConfiguration(topicSuffix: nil).isValid && !isSending
  }

  // MARK: - Build Payload
  func buildPayload() -> NativePushPayload {
    var alert: NativeAlert?
    if pushType == .alert {
      let t = title.isEmpty ? nil : title
      let s = subtitle.isEmpty ? nil : subtitle
      let b = body.isEmpty ? nil : body
      // Only include alert key if there is at least some visible content
      if t != nil || s != nil || b != nil {
        alert = NativeAlert(title: t, subtitle: s, body: b)
      }
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

    if pushType == .alert && title.isEmpty && body.isEmpty {
      showToastMessage("Alert notifications require at least a title or body.", type: .error)
      return
    }

    isSending = true

    let validTokens = allValidTokens
    let payload = buildPayload()
    let configuration = config.apnsConfiguration(topicSuffix: nil)

    let group = DispatchGroup()
    var responses: [APNsResponse] = []
    var firstError: Error?

    for token in validTokens {
      group.enter()
      APNsService.shared.sendNativePush(
        payload: payload,
        token: token,
        pushType: pushType,
        priority: priority,
        configuration: configuration
      ) { result in
        switch result {
        case .success(let response):
          responses.append(response)
        case .failure(let error):
          if firstError == nil { firstError = error }
          if case APNsService.APNsError.requestFailed(let response) = error {
            responses.append(response)
          }
        }
        group.leave()
      }
    }

    group.notify(queue: .main) { [weak self] in
      guard let self else { return }
      self.isSending = false
      self.lastResponse = responses.last
      if let error = firstError {
        self.showToastMessage(error.localizedDescription, type: .error)
      } else {
        let msg = responses.count == 1
          ? responses[0].summary
          : "\(responses.count) pushes sent"
        self.showToastMessage(msg, type: .success)
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

    let cleanToken = (allValidTokens.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
    if allValidTokens.count > 1 {
      lines.append("# cURL shown for the first token. Repeat for each additional token.")
    }
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
  func pasteToken(at index: Int) {
    guard let clipboardString = NSPasteboard.general.string(forType: .string) else { return }
    let trimmed = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
    let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
    if trimmed.unicodeScalars.allSatisfy({ hexCharacterSet.contains($0) }) && !trimmed.isEmpty {
      if index < tokens.count {
        tokens[index] = trimmed
      }
    } else {
      showToastMessage("Invalid token format. Expected hex string.", type: .error)
    }
  }

  // MARK: - Toast
  func showToastMessage(_ message: String, type: ToastType) {
    toastMessage = message
    toastType = type
    showToast = true
  }
}
