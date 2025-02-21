//
//  ContentView.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import SwiftUI

struct ContentView: View {
  @State private var tokens: [String] = [""]
  @State private var title: String = ""
  @State private var notificationBody: String = ""
  @State private var sound: String = "default"
  @State private var priority: PushNotification.Priority = .default
  @State private var ttl: String = ""
  @State private var expiration: String = ""
  @State private var data: [String: String] = [:]
  
  // New state variables for advanced fields
  @State private var showAdvancedSettings: Bool = false
  @State private var subtitle: String = ""
  @State private var badge: String = ""
  @State private var interruptionLevel: PushNotification.InterruptionLevel = .active
  @State private var channelId: String = ""
  @State private var categoryId: String = ""
  @State private var mutableContent: Bool = false
  @State private var contentAvailable: Bool = false
  
  var body: some View {
    VStack(spacing: 16) {
      // Title
      Text("QuickPush")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
      
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
                TextField("Push Token e.g. ExponentPushToken[N1QHiEF4mnLGP8HeQrj9AR]", text: $tokens[index])
                  .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if let clipboardString = NSPasteboard.general.string(forType: .string) {
                        // Valid token length is 41 characters (ExponentPushToken[xxxxxxxxxxxxxxxxxxxxx])
                        let trimmed = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.count <= 41 && trimmed.starts(with: "ExponentPushToken[") && trimmed.hasSuffix("]") {
                            tokens[index] = trimmed
                        } else {
                            showAlert(title: "Invalid Token", 
                                    message: "Token should be in format: ExponentPushToken[xxxxxxxxxxxxxxxxxxxxx]")
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
            
            Divider()
            
            // Basic Notification Fields
            VStack(alignment: .leading, spacing: 8) {
              InputField(label: "Title", text: $title, helpText: "Title of the notification")
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
            .foregroundColor(.primary)
          }
          .buttonStyle(.plain)
          
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
      
      // Send Button
      Button("Send Push") {
        sendPushNotification()
      }
      .buttonStyle(.borderedProminent)
      .frame(maxWidth: .infinity)
    }
    .padding()
    .frame(minHeight: 460, maxHeight: showAdvancedSettings ? 650 : 460)
  }
  
  private func sendPushNotification() {
    let validTokens = tokens.filter { !$0.isEmpty }
    
    guard !validTokens.isEmpty, !title.isEmpty else {
      print("Error: Missing required fields")
      return
    }
    
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
    
    PushNotificationService.shared.sendPushNotification(notification: notification) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let response):
          print("Push sent successfully: \(response)")
          showAlert(title: "Success", message: "Push notification sent!")
        case .failure(let error):
          print("Failed to send push: \(error.localizedDescription)")
          showAlert(title: "Error", message: error.localizedDescription)
        }
      }
    }
  }
  
  // Helper function to show alerts
  private func showAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }
}

// MARK: - Reusable InputField with Tooltip
struct InputField: View {
  let label: String
  @Binding var text: String
  let helpText: String
  
  var body: some View {
    HStack {
      Text("\(label):")
      TextField(label, text: $text)
        .textFieldStyle(RoundedBorderTextFieldStyle())
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
