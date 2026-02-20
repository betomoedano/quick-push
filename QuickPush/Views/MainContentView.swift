//
//  MainContentView.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

/// Shared root view used by both the MenuBarExtra popover and the floating panel.
struct MainContentView: View {
  @Environment(WindowManager.self) var windowManager

  var body: some View {
    VStack {
      ContentView()
      Divider()
      FooterView()
    }
    .frame(minWidth: 570)
  }
}
