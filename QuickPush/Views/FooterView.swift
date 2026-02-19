//
//  FooterView.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI
import LaunchAtLogin

/// Footer shown at the bottom of the app with launch-at-login toggle,
/// pin/unpin button, quit button, and attribution.
struct FooterView: View {
  @Environment(WindowManager.self) var windowManager
  @State private var showCopied = false

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
  }

  private let appStoreURL = URL(string: "https://apple.co/4tvT4wF")!

  var body: some View {
    VStack(spacing: 6) {
      // Main row: launch at login, utility icons, pin
      HStack(spacing: 12) {
        LaunchAtLogin.Toggle()

        Spacer()

        Button {
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(appStoreURL.absoluteString, forType: .string)
          showCopied = true
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopied = false
          }
        } label: {
          Image(systemName: showCopied ? "checkmark" : "square.and.arrow.up")
            .animation(.easeInOut, value: showCopied)
        }
        .help("Share QuickPush — copies App Store link to clipboard")

        Link(destination: URL(string: "https://github.com/betomoedano/quick-push")!) {
          Image(systemName: "book.closed")
        }
        .help("Open documentation on GitHub")

        Button {
          NSWorkspace.shared.open(appStoreURL)
        } label: {
          Image(systemName: "arrow.triangle.2.circlepath")
        }
        .help("Check for updates on the App Store")

        Button {
          windowManager.togglePin()
        } label: {
          Image(systemName: windowManager.isPinned ? "pin.slash.fill" : "pin.fill")
        }
        .help(windowManager.isPinned ? "Unpin Window" : "Pin Window (⌘⇧P)")
      }
      .buttonStyle(.borderless)
      .imageScale(.medium)
      .foregroundStyle(.secondary)

      // Bottom row: version left, attribution right
      HStack {
        Text("v\(appVersion)")
          .foregroundStyle(.tertiary)
        Spacer()
        HStack(spacing: 0) {
          Text("Made with ❤️ by ")
          Link("codewithbeto.dev", destination: URL(string: "https://codewithbeto.dev")!)
            .foregroundColor(.blue)
        }
      }
      .font(.caption)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
  }
}
