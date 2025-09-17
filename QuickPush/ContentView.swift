//
//  ContentView.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import SwiftUI

struct ContentView: View {
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
  
  // New state variables for advanced fields
  @State private var showAdvancedSettings: Bool = false
  @State private var subtitle: String = ""
  @State private var badge: String = ""
  @State private var interruptionLevel: PushNotification.InterruptionLevel = .active
  @State private var channelId: String = ""
  @State private var categoryId: String = ""
  @State private var mutableContent: Bool = false
  @State private var contentAvailable: Bool = false
  
  // Toast notification state
  @State private var showToast: Bool = false
  @State private var toastMessage: String = ""
  @State private var toastType: ToastType = .success
  
  var body: some View {
    VStack(spacing: 16) {
      // Title and Send Button
      HStack {
        Text("QuickPush")
          .font(.headline)
        Spacer()
        Button("Send Push") {
          sendPushNotification()
        }
        .buttonStyle(.borderedProminent)
        .disabled(tokens.filter { !$0.isEmpty }.isEmpty) // Disable if no valid tokens
      }
      
      // Main Content
      ScrollView(.vertical, showsIndicators: false) {
        VStack(alignment: .leading, spacing: 16) {
          // Basic Fields Section
          VStack(alignment: .leading, spacing: 12) {
            // Tokens Section
            Text("Expo Push Tokens:")
              .font(.subheadline)
            
            ForEach(tokens.indices, id: \.self) { index in
              HStack {
                TextField("e.g. ExponentPushToken[N1QHiEF4mnLGP8HeQrj9AR]", text: $tokens[index])
                  .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if let clipboardString = NSPasteboard.general.string(forType: .string) {
                        // Valid token length is 41 characters (ExponentPushToken[xxxxxxxxxxxxxxxxxxxxx])
                        let trimmed = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.count <= 41 && trimmed.starts(with: "ExponentPushToken[") && trimmed.hasSuffix("]") {
                            tokens[index] = trimmed
                        } else {
                            showToast(message: "Token should be in format: ExponentPushToken[xxxxxxxxxxxxxxxxxxxxx]", type: .error)
                        }
                    }
                }) {
                    Image(systemName: "doc.on.clipboard")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Paste from clipboard (ExponentPushToken[xxxxxxxxxxxxxxxxxxxxx])")
                
                if tokens.count > 1 {
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
                
                InputField(label: "Category ID", text: $categoryId, helpText: "Notification category for interactive notifications")
                InputField(label: "TTL", text: $ttl, helpText: "Time-to-live in seconds")
                InputField(label: "Expiration", text: $expiration, helpText: "Unix timestamp for expiration")
              }
            }
          }
        }
      }
    }
    .padding()
    .frame(minHeight: 410, maxHeight: showAdvancedSettings ? 650 : 410)
    .overlay(
      ToastView(message: toastMessage, type: toastType, isPresented: $showToast)
        .animation(.easeInOut, value: showToast)
    )
  }
  
  private func sendPushNotification() {
    let validTokens = tokens.filter { !$0.isEmpty }
    
    guard !validTokens.isEmpty, !title.isEmpty else {
      showTitleError = title.isEmpty
      if title.isEmpty {
        showToast(message: "Title is required", type: .error)
      }
      return
    }
    
    showTitleError = false
    
    let notification = PushNotification(
      to: validTokens,
      title: title,
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
      contentAvailable: contentAvailable
    )
    
    PushNotificationService.shared.sendPushNotification(
      notification: notification,
      accessToken: accessToken.isEmpty ? nil : accessToken
    ) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let response):
          print("Push sent successfully: \(response)")
          showToast(message: "Push notification sent successfully!", type: .success)
        case .failure(let error):
          print("Failed to send push: \(error.localizedDescription)")
          showToast(message: error.localizedDescription, type: .error)
        }
      }
    }
  }
  
  private func showToast(message: String, type: ToastType) {
    toastMessage = message
    toastType = type
    showToast = true
  }
}

// MARK: - Toast Types and View
enum ToastType {
  case success
  case error
  
  var backgroundColor: Color {
    switch self {
    case .success: return Color.green.opacity(0.9)
    case .error: return Color.red.opacity(0.9)
    }
  }
  
  var icon: String {
    switch self {
    case .success: return "checkmark.circle.fill"
    case .error: return "exclamationmark.circle.fill"
    }
  }
}

struct ToastView: View {
  let message: String
  let type: ToastType
  @Binding var isPresented: Bool
  
  var body: some View {
    VStack {
      Spacer()
      if isPresented {
        HStack(spacing: 12) {
          Image(systemName: type.icon)
          Text(message)
            .foregroundColor(.white)
        }
        .padding()
        .background(type.backgroundColor)
        .cornerRadius(8)
        .padding(.bottom, 20)
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
              isPresented = false
            }
          }
        }
      }
    }
  }
}

// MARK: - Reusable InputField with Tooltip
struct InputField: View {
  let label: String
  @Binding var text: String
  let helpText: String
  var isRequired: Bool = false
  var showError: Bool = false
  
  var body: some View {
    HStack {
      Text("\(label):")
      TextField(label, text: $text)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .overlay(
          RoundedRectangle(cornerRadius: 6)
            .stroke(showError ? Color.red : Color.clear, lineWidth: 1)
        )
      HelpButton(helpText: helpText)
    }
  }
}

// MARK: - Help Button with Popover
struct HelpButton: View {
  let helpText: String
  @State private var showHelp = false
  
  var body: some View {
    Button(action: { showHelp.toggle() }) {
      Image(systemName: "questionmark.circle")
        .foregroundColor(.secondary)
    }
    .popover(isPresented: $showHelp) {
      Text(helpText)
        .padding()
        .frame(width: 250)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
#Preview {
  ContentView()
}
