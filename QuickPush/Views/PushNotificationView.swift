//
//  PushNotificationView.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

struct PushNotificationView: View {
  @Environment(WindowManager.self) var windowManager
  @State private var tokens: [String] = [""]
  @State private var accessToken: String = ""
  @State private var title: String = ""
  @State private var notificationBody: String = ""
  @State private var sound: String = "default"
  @State private var priority: PushNotification.Priority = .default
  @State private var ttl: String = ""
  @State private var expiration: String = ""
  @State private var data: [String: String] = [:]
  @State private var showTitleError: Bool = false

  // Advanced fields
  @State private var showAdvancedSettings: Bool = true
  @State private var subtitle: String = ""
  @State private var badge: String = ""
  @State private var interruptionLevel: PushNotification.InterruptionLevel = .active
  @State private var channelId: String = ""
  @State private var categoryId: String = ""
  @State private var mutableContent: Bool = false
  @State private var contentAvailable: Bool = false
  @State private var imageUrl: String = ""

  // Toast notification state
  @State private var showToast: Bool = false
  @State private var toastMessage: String = ""
  @State private var toastType: ToastType = .success

  // Response & cURL sheet state
  @State private var lastResponse: PushResponse?
  @State private var lastHttpStatusCode: Int?
  @State private var lastRawJSON: String?
  @State private var showResponseSheet: Bool = false
  @State private var showCurlSheet: Bool = false

  // Saved tokens state
  @State private var savedTokens: [SavedToken] = []
  @State private var tokenToSave: TokenToSave? = nil

  var body: some View {
    VStack {
      // Title and Send Button
      HStack {
        Text("Expo Notification")
          .font(.headline)
        Spacer()
        if lastResponse != nil {
          Button {
            showResponseSheet = true
          } label: {
            HStack(spacing: 4) {
              Circle()
                .fill(responseHasErrors ? Color.red : Color.green)
                .frame(width: 6, height: 6)
              Text("Response")
            }
          }
          .controlSize(.small)
        }
        Button("cURL") {
          showCurlSheet = true
        }
        .controlSize(.small)
        .disabled(allValidTokens.isEmpty || title.isEmpty)
        Button {
          sendPushNotification()
        } label: {
          HStack(spacing: 4) {
            Text("Send Push")
            HStack(spacing: 1) {
              Image(systemName: "command")
              Image(systemName: "return")
            }
            .font(.caption2)
            .opacity(0.7)
          }
        }
        .keyboardShortcut(.return, modifiers: .command)
        .applying { view in
          if #available(macOS 26.0, *) {
            view.buttonStyle(.glassProminent)
          } else {
            view.buttonStyle(.borderedProminent)
          }
        }
        .disabled(allValidTokens.isEmpty)
      }

      // Main Content
      ScrollView(.vertical, showsIndicators: false) {
        VStack(alignment: .leading, spacing: 12) {
          // Basic Fields Section
          VStack(alignment: .leading, spacing: 12) {
            // Tokens Section
            Text("Expo Push Tokens:")
              .font(.subheadline)

            // Saved tokens (compact display)
            ForEach(savedTokens) { saved in
              SavedTokenRowView(
                savedToken: saved,
                onToggle: {
                  if let index = savedTokens.firstIndex(where: { $0.id == saved.id }) {
                    savedTokens[index].isEnabled.toggle()
                    SavedTokenStore.shared.saveTokens(savedTokens)
                  }
                },
                onCopy: {
                  NSPasteboard.general.clearContents()
                  NSPasteboard.general.setString(saved.token, forType: .string)
                  showToastNotification(message: "Token copied to clipboard", type: .success)
                },
                onRemove: {
                  SavedTokenStore.shared.removeToken(id: saved.id)
                  savedTokens.removeAll { $0.id == saved.id }
                }
              )
            }

            // Unsaved token rows (text fields)
            ForEach(tokens.indices, id: \.self) { index in
              HStack(spacing: 8) {
                TextField("e.g. ExponentPushToken[N1QHiEF4mnLGP8HeQrj9AR]", text: $tokens[index])
                  .textFieldStyle(RoundedBorderTextFieldStyle())
                  .padding(.leading, 4)

                // Paste from clipboard
                Button(action: {
                  if let clipboardString = NSPasteboard.general.string(forType: .string) {
                    let trimmed = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.count <= 41 && trimmed.starts(with: "ExponentPushToken[") && trimmed.hasSuffix("]") {
                      tokens[index] = trimmed
                    } else {
                      showToastNotification(message: "Token should be in format: ExponentPushToken[xxxxxxxxxxxxxxxxxxxxx]", type: .error)
                    }
                  }
                }) {
                  Image(systemName: "doc.on.clipboard")
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Paste from clipboard (ExponentPushToken[xxxxxxxxxxxxxxxxxxxxx])")

                // Save token for future sessions
                Button(action: {
                  tokenToSave = TokenToSave(index: index, token: tokens[index])
                }) {
                  Image(systemName: "square.and.arrow.down")
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(tokens[index].trimmingCharacters(in: .whitespaces).isEmpty)
                .help("Save this token for future sessions")

                // Delete token row
                if tokens.count > 1 || !savedTokens.isEmpty {
                  Button(action: { tokens.remove(at: index) }) {
                    Image(systemName: "minus.circle.fill")
                      .foregroundColor(.red)
                  }
                  .buttonStyle(PlainButtonStyle())
                }
              }
            }

            Button(action: { tokens.append("") }) {
              HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Token")
              }
            }
            .buttonStyle(.borderless)
            .padding(.top, 5)

            // Access Token Section
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("Access Token (Optional):")
                  .font(.subheadline)
                HelpButton(helpText: "Enhanced push security token. Required if you've enabled push security in your EAS Dashboard.")
              }

              HStack {
                SecureField("Access token for enhanced security", text: $accessToken)
                  .textFieldStyle(RoundedBorderTextFieldStyle())
                  .padding(.leading, 4)

                Button(action: {
                  if let clipboardString = NSPasteboard.general.string(forType: .string) {
                    let trimmed = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
                    accessToken = trimmed
                  }
                }) {
                  Image(systemName: "doc.on.clipboard")
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Paste access token from clipboard")
              }
            }

            Divider()

            // Basic Notification Fields
            VStack(alignment: .leading, spacing: 8) {
              InputField(label: "Title", text: $title, helpText: "Title of the notification", isRequired: true, showError: showTitleError)
              InputField(label: "Body", text: $notificationBody, helpText: "Message content displayed in the notification")

              // Priority Picker
              HStack {
                Text("Priority:")
                Picker("", selection: $priority) {
                  Text("Default").tag(PushNotification.Priority.default)
                  Text("Normal").tag(PushNotification.Priority.normal)
                  Text("High").tag(PushNotification.Priority.high)
                }
                .pickerStyle(SegmentedPickerStyle())

                HelpButton(helpText: "Affects delivery timing. 'High' wakes sleeping devices.")
              }

              Divider()
              KeyValueInputView(data: $data)
            }
          }

          // Advanced Settings Toggle
          Button(action: { showAdvancedSettings.toggle() }) {
            HStack {
              Text("Advanced Settings")
                .font(.subheadline)
              Spacer()
              Image(systemName: showAdvancedSettings ? "chevron.up" : "chevron.down")
            }
          }
          .buttonStyle(.borderless)

          if showAdvancedSettings {
            VStack(alignment: .leading, spacing: 12) {
              // iOS Specific Settings
              Group {
                Text("iOS Specific")
                  .font(.subheadline)
                  .foregroundColor(.secondary)

                InputField(label: "Sound", text: $sound, helpText: "Specify 'default' or custom sound name (iOS only)")
                InputField(label: "Subtitle", text: $subtitle, helpText: "Additional text below the title (iOS only)")
                InputField(label: "Badge", text: $badge, helpText: "Number to display on app icon (iOS only)")

                // Interruption Level Picker
                HStack {
                  Text("Interruption Level:")
                  Picker("", selection: $interruptionLevel) {
                    Text("Active").tag(PushNotification.InterruptionLevel.active)
                    Text("Critical").tag(PushNotification.InterruptionLevel.critical)
                    Text("Passive").tag(PushNotification.InterruptionLevel.passive)
                    Text("Time Sensitive").tag(PushNotification.InterruptionLevel.timeSensitive)
                  }
                  .pickerStyle(MenuPickerStyle())

                  HelpButton(helpText: "Controls the delivery timing and importance of the notification")
                }

                Toggle("Mutable Content", isOn: $mutableContent)
                  .help("Allows notification content modification by the app")

                Toggle("Content Available", isOn: $contentAvailable)
                  .help("Triggers background fetch on delivery")
              }

              Divider()

              // Android Specific Settings
              Group {
                Text("Android Specific")
                  .font(.subheadline)
                  .foregroundColor(.secondary)

                InputField(label: "Channel ID", text: $channelId, helpText: "Android notification channel identifier")
              }

              Divider()

              // Common Advanced Settings
              Group {
                Text("Common Settings")
                  .font(.subheadline)
                  .foregroundColor(.secondary)

                InputField(label: "Image (richContent)", text: $imageUrl, helpText: "URL of image to display in rich notification. Android shows it out of the box. iOS requires a Notification Service Extension — learn how in this free lesson: https://codewithbeto.dev/rnCourse/expoNotificationsExtension See also https://github.com/expo/expo/pull/36202")
                InputField(label: "Category ID", text: $categoryId, helpText: "Notification category for interactive notifications")
                InputField(label: "TTL", text: $ttl, helpText: "Time-to-live in seconds")
                InputField(label: "Expiration", text: $expiration, helpText: "Unix timestamp for expiration")
              }
            }
          }
        }
      }
    }
    .padding(.horizontal)
    .padding(.top)
    .overlay(
      ToastView(message: toastMessage, type: toastType, isPresented: $showToast)
        .animation(.easeInOut, value: showToast)
    )
    .adaptivePresentation(isPresented: $showResponseSheet, isPinned: windowManager.isPinned) {
      ExpoResponseDetailView(
        response: lastResponse,
        httpStatusCode: lastHttpStatusCode,
        rawJSON: lastRawJSON
      )
    }
    .adaptivePresentation(isPresented: $showCurlSheet, isPinned: windowManager.isPinned) {
      ExpoCurlCommandView(
        notification: buildNotification(),
        accessToken: accessToken.isEmpty ? nil : accessToken
      )
    }
    .adaptivePresentation(item: $tokenToSave, isPinned: windowManager.isPinned) { item in
      SaveTokenSheet(token: item.token) { label in
        let savedToken = SavedToken(label: label, token: item.token)
        SavedTokenStore.shared.addToken(savedToken)
        savedTokens.append(savedToken)

        // Move from unsaved to saved
        if item.index < tokens.count {
          tokens.remove(at: item.index)
        }
        if tokens.isEmpty {
          tokens.append("")
        }
      }
    }
    .onAppear {
      savedTokens = SavedTokenStore.shared.loadTokens()
    }
  }

  /// All valid tokens from both saved (enabled only) and unsaved sources.
  private var allValidTokens: [String] {
    savedTokens.filter(\.isEnabled).map(\.token) + tokens.filter { !$0.isEmpty }
  }

  /// Whether the last response contains errors (API-level or per-ticket).
  private var responseHasErrors: Bool {
    guard let response = lastResponse else { return false }
    if let errors = response.errors, !errors.isEmpty { return true }
    if let tickets = response.data, tickets.contains(where: { $0.status == "error" }) { return true }
    return false
  }

  /// Build a `PushNotification` from the current form values.
  private func buildNotification() -> PushNotification {
    let validTokens = allValidTokens
    let richContent: PushNotification.RichContent? = imageUrl.isEmpty ? nil : PushNotification.RichContent(image: imageUrl)

    return PushNotification(
      to: validTokens.isEmpty ? ["ExponentPushToken[...]"] : validTokens,
      title: title.isEmpty ? "Title" : title,
      body: notificationBody.isEmpty ? " " : notificationBody,
      data: data.isEmpty ? nil : data,
      ttl: Int(ttl),
      expiration: Int(expiration),
      priority: priority,
      subtitle: subtitle.isEmpty ? nil : subtitle,
      sound: sound.isEmpty ? nil : sound,
      badge: Int(badge),
      interruptionLevel: interruptionLevel,
      channelId: channelId.isEmpty ? nil : channelId,
      categoryId: categoryId.isEmpty ? nil : categoryId,
      mutableContent: mutableContent,
      contentAvailable: contentAvailable,
      richContent: richContent
    )
  }

  private func sendPushNotification() {
    let validTokens = allValidTokens

    guard !validTokens.isEmpty, !title.isEmpty else {
      showTitleError = title.isEmpty
      if title.isEmpty {
        showToastNotification(message: "Title is required", type: .error)
      }
      return
    }

    showTitleError = false

    let notification = buildNotification()

    PushNotificationService.shared.sendPushNotification(
      notification: notification,
      accessToken: accessToken.isEmpty ? nil : accessToken
    ) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let sendResult):
          lastResponse = sendResult.response
          lastHttpStatusCode = sendResult.httpStatusCode
          lastRawJSON = sendResult.rawJSON
          print("Push sent successfully: \(sendResult.response)")
          showToastNotification(message: "Push notification sent successfully!", type: .success)
        case .failure(let error):
          print("Failed to send push: \(error.localizedDescription)")
          showToastNotification(message: error.localizedDescription, type: .error)
        }
      }
    }
  }

  private func showToastNotification(message: String, type: ToastType) {
    toastMessage = message
    toastType = type
    showToast = true
  }
}

// MARK: - Token Save Sheet Item

/// Identifiable wrapper for the `.sheet(item:)` presentation.
struct TokenToSave: Identifiable {
  let id = UUID()
  let index: Int
  let token: String
}
