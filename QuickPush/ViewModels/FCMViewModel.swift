//
//  FCMViewModel.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

@Observable
class FCMViewModel {
  // MARK: - Shared FCM config
  var config: FCMConfigStore = .shared

  // MARK: - Tokens
  var tokens: [String] = [""]
  var savedTokens: [SavedToken] = []

  var allValidTokens: [String] {
    savedTokens.filter(\.isEnabled).map(\.token) + tokens.filter { !$0.isEmpty }
  }

  // MARK: - Message fields
  var messageType: FCMMessageType = .notification
  var title: String = ""
  var body: String = ""
  var imageUrl: String = ""
  var channelId: String = "default"
  var sound: String = "default"
  var color: String = ""
  var priority: String = "HIGH"
  var customData: [String: String] = [:]

  // MARK: - UI State
  var isSending: Bool = false
  var showToast: Bool = false
  var toastMessage: String = ""
  var toastType: ToastType = .success
  var showResponseSheet: Bool = false
  var showCurlSheet: Bool = false
  var lastResponse: FCMResponse?
  var tokenToSave: TokenToSave?
  var curlCommand: String = ""

  // MARK: - Init
  init() {
    savedTokens = SavedTokenStore.fcm.loadTokens()
  }

  // MARK: - Validation
  var canSend: Bool {
    !allValidTokens.isEmpty && config.fcmConfiguration().isValid && !isSending
  }

  // MARK: - Build Message
  func buildMessage(token: String) -> FCMMessage {
    var notification: FCMNotification?
    if messageType == .notification {
      notification = FCMNotification(
        title: title.isEmpty ? nil : title,
        body: body.isEmpty ? nil : body,
        image: imageUrl.isEmpty ? nil : imageUrl
      )
    }

    var androidNotification: FCMAndroidNotification?
    if messageType == .notification {
      androidNotification = FCMAndroidNotification(
        channelId: channelId.isEmpty ? nil : channelId,
        sound: sound.isEmpty ? nil : sound,
        color: color.isEmpty ? nil : "#\(color.trimmingCharacters(in: CharacterSet(charactersIn: "#")))"
      )
    }

    let androidConfig = FCMAndroidConfig(
      priority: priority,
      notification: androidNotification
    )

    let data = customData.isEmpty ? nil : customData

    return FCMMessage(
      token: token,
      notification: notification,
      android: androidConfig,
      data: data
    )
  }

  // MARK: - Send
  func send() {
    guard canSend else { return }

    if messageType == .notification && title.isEmpty && body.isEmpty {
      showToastMessage("Notification messages require at least a title or body.", type: .error)
      return
    }

    isSending = true

    let validTokens = allValidTokens
    let configuration = config.fcmConfiguration()

    let group = DispatchGroup()
    var responses: [FCMResponse] = []
    var firstError: Error?

    for token in validTokens {
      let message = buildMessage(token: token)
      group.enter()
      FCMService.shared.send(
        message: message,
        configuration: configuration
      ) { result in
        switch result {
        case .success(let response):
          responses.append(response)
        case .failure(let error):
          if firstError == nil { firstError = error }
          if case FCMService.FCMError.requestFailed(let response) = error {
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
    let configuration = config.fcmConfiguration()
    let cleanToken = (allValidTokens.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let message = buildMessage(token: cleanToken.isEmpty ? "<FCM_REGISTRATION_TOKEN>" : cleanToken)

    let body = FCMRequestBody(message: message)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let bodyString: String
    if let data = try? encoder.encode(body),
       let str = String(data: data, encoding: .utf8) {
      bodyString = str
    } else {
      bodyString = "{}"
    }

    var lines: [String] = []
    lines.append("# Replace <ACCESS_TOKEN> with a valid OAuth 2.0 bearer token.")
    lines.append("# Obtain one by running: gcloud auth print-access-token")
    if allValidTokens.count > 1 {
      lines.append("# cURL shown for the first token. Repeat for each additional token.")
    }
    lines.append("curl -X POST \\")
    lines.append("  https://fcm.googleapis.com/v1/projects/\(configuration.projectId)/messages:send \\")
    lines.append("  -H \"Authorization: Bearer <ACCESS_TOKEN>\" \\")
    lines.append("  -H \"Content-Type: application/json\" \\")
    lines.append("  -d '\(bodyString)'")

    return lines.joined(separator: "\n")
  }

  // MARK: - Clipboard
  func pasteToken(at index: Int) {
    guard let clipboardString = NSPasteboard.general.string(forType: .string) else { return }
    let trimmed = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      showToastMessage("Clipboard is empty.", type: .error)
      return
    }
    if index < tokens.count {
      tokens[index] = trimmed
    }
  }

  // MARK: - Toast
  func showToastMessage(_ message: String, type: ToastType) {
    toastMessage = message
    toastType = type
    showToast = true
  }
}
