//
//  QuickPushApp.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import SwiftUI

@main
struct QuickPushApp: App {
  var body: some Scene {
    MenuBarExtra("QuickPush", systemImage: "bell.badge.waveform.fill") {
      ContentView()
        .frame(minWidth: 500)
    }
    .menuBarExtraStyle(.window)
  }
}
