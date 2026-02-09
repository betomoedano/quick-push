//
//  ContentView.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import SwiftUI

enum AppTab: String, CaseIterable {
  case pushNotification = "Push Notification"
  case liveActivity = "Live Activity"
}

struct ContentView: View {
  @State private var selectedTab: AppTab = .pushNotification

  var body: some View {
    VStack(spacing: 0) {
      // Tab Picker
      Picker("", selection: $selectedTab) {
        ForEach(AppTab.allCases, id: \.self) { tab in
          Text(tab.rawValue).tag(tab)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)
      .padding(.top, 12)
      .padding(.bottom, 8)

      // Tab Content
      switch selectedTab {
      case .pushNotification:
        PushNotificationView()
      case .liveActivity:
        LiveActivityView()
      }
    }
    .frame(minHeight: 410, maxHeight: 700)
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
