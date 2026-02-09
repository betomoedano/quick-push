//
//  QuickPushApp.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import SwiftUI

@main
struct QuickPushApp: App {
  @State private var windowManager = WindowManager()

  var body: some Scene {
    MenuBarExtra("QuickPush", systemImage: "bolt.brakesignal") {
      MainContentView()
        .environment(windowManager)
        .onAppear {
          // Register the global hotkey after the app has launched.
          windowManager.startMonitoring()

          // If the panel is already pinned, bring it to front
          // instead of showing the popover content.
          if windowManager.isPinned {
            windowManager.bringPanelToFront()
          }
        }
    }
    .menuBarExtraStyle(.window)
  }
}
