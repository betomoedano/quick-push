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
    MenuBarExtra("QuickPush", systemImage: "bell") {
      ContentView()
        .frame(minWidth: 400)
    }
    .menuBarExtraStyle(.window)
  }
}
