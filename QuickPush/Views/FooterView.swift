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

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        LaunchAtLogin.Toggle()
        Spacer()

        Button {
          windowManager.togglePin()
        } label: {
          Image(systemName: windowManager.isPinned ? "pin.slash.fill" : "pin.fill")
        }
        .help(windowManager.isPinned ? "Unpin Window" : "Pin Window (⌘⇧P)")
        .buttonStyle(.borderless)

        Button("Quit") {
          NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
      }
      HStack(spacing: 0) {
        Text("Made with ❤️ by ")
        Link("codewithbeto.dev", destination: URL(string: "https://codewithbeto.dev")!)
          .foregroundColor(.blue)
      }
      .font(.caption)
    }
    .padding()
  }
}
