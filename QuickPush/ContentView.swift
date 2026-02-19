//
//  ContentView.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import SwiftUI

enum AppTab: String, CaseIterable {
  case pushNotification = "Expo Notification"
  case liveActivity = "Live Activity"
  case apnsPush = "APNs"
  case fcm = "FCM"

  var icon: String {
    switch self {
    case .pushNotification: return "bell.badge"
    case .liveActivity: return "waveform"
    case .apnsPush: return "antenna.radiowaves.left.and.right"
    case .fcm: return "server.rack"
    }
  }

  /// Label shown in the segmented picker, embedding the ⌘N shortcut hint.
  var tabLabel: String {
    switch self {
    case .pushNotification: return "Expo Notification  ⌘1"
    case .liveActivity: return "Live Activity  ⌘2"
    case .apnsPush: return "APNs  ⌘3"
    case .fcm: return "FCM  ⌘4"
    }
  }
}

struct ContentView: View {
  @State private var selectedTab: AppTab = .pushNotification

  var body: some View {
    VStack(spacing: 0) {
      // Tab Picker
      Picker("", selection: $selectedTab) {
        ForEach(AppTab.allCases, id: \.self) { tab in
          Label(tab.tabLabel, systemImage: tab.icon).tag(tab)
        }
      }
      .pickerStyle(.segmented)
      .padding(.top, 12)
      .padding(.bottom, 4)

      // Tab Content — all views stay alive so @State is preserved
      PushNotificationView(isActive: selectedTab == .pushNotification)
        .opacity(selectedTab == .pushNotification ? 1 : 0)
        .frame(height: selectedTab == .pushNotification ? nil : 0)
        .allowsHitTesting(selectedTab == .pushNotification)

      LiveActivityView(isActive: selectedTab == .liveActivity)
        .opacity(selectedTab == .liveActivity ? 1 : 0)
        .frame(height: selectedTab == .liveActivity ? nil : 0)
        .allowsHitTesting(selectedTab == .liveActivity)

      APNsView(isActive: selectedTab == .apnsPush)
        .opacity(selectedTab == .apnsPush ? 1 : 0)
        .frame(height: selectedTab == .apnsPush ? nil : 0)
        .allowsHitTesting(selectedTab == .apnsPush)

      FCMView(isActive: selectedTab == .fcm)
        .opacity(selectedTab == .fcm ? 1 : 0)
        .frame(height: selectedTab == .fcm ? nil : 0)
        .allowsHitTesting(selectedTab == .fcm)
    }
    .frame(minHeight: 410)
    // ⌘1/2/3/4 to switch tabs
    .background(
      Group {
        Button("") { selectedTab = .pushNotification }
          .keyboardShortcut("1", modifiers: .command)
        Button("") { selectedTab = .liveActivity }
          .keyboardShortcut("2", modifiers: .command)
        Button("") { selectedTab = .apnsPush }
          .keyboardShortcut("3", modifiers: .command)
        Button("") { selectedTab = .fcm }
          .keyboardShortcut("4", modifiers: .command)
      }
      .frame(width: 0, height: 0)
      .opacity(0)
    )
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

  private var dismissDelay: TimeInterval {
    type == .error ? 5 : 3
  }

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
          DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
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
      VStack(alignment: .leading, spacing: 8) {
        Text(attributedHelpText)
          .textSelection(.enabled)
      }
      .padding()
      .frame(width: 300)
    }
    .buttonStyle(PlainButtonStyle())
  }

  private var attributedHelpText: AttributedString {
    var attributedString = AttributedString(helpText)
    // Find all URLs and make them clickable
    var searchStart = helpText.startIndex
    while let urlRange = helpText.range(of: "https://[^\\s]+", options: .regularExpression, range: searchStart..<helpText.endIndex),
          let url = URL(string: String(helpText[urlRange])),
          let attrRange = attributedString.range(of: String(helpText[urlRange])) {
      attributedString[attrRange].link = url
      attributedString[attrRange].foregroundColor = .blue
      attributedString[attrRange].underlineStyle = .single
      searchStart = urlRange.upperBound
    }
    return attributedString
  }
}

#Preview {
  ContentView()
}
