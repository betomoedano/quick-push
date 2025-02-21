//
//  QuickPushApp.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import SwiftUI
import LaunchAtLogin

@main
struct QuickPushApp: App {
  var body: some Scene {
    MenuBarExtra("QuickPush", systemImage: "bell.badge.waveform.fill") {
      VStack {
        ContentView()
        Divider()
        VStack(spacing: 8) {
          HStack {
            LaunchAtLogin.Toggle()
            Spacer()
            Button("Quit") {
              NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
          }
          HStack(spacing: 0) { // Ensures no extra spacing
              Text("Made with ❤️ by ")
              Link("codewithbeto.dev", destination: URL(string: "https://codewithbeto.dev")!)
                  .foregroundColor(.blue)
          }
          .font(.caption)
        }
        .padding()
      }
      .frame(minWidth: 400)
    }
    .menuBarExtraStyle(.window)
  }
}
