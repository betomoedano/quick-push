//
//  FloatingPanel.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import AppKit

/// A floating NSPanel that stays on top of other windows.
/// Used for the "Pin Window" feature so the app persists
/// even when the user clicks outside.
final class FloatingPanel: NSPanel {

  /// Called when the user closes the panel via the title-bar X button.
  /// The WindowManager sets this so it can run `unpin()` cleanly.
  var onClose: (() -> Void)?

  init(contentRect: NSRect) {
    super.init(
      contentRect: contentRect,
      styleMask: [
        .titled,
        .closable,
        .resizable,
        .fullSizeContentView
      ],
      backing: .buffered,
      defer: false
    )

    level = .floating
    isFloatingPanel = true
    hidesOnDeactivate = false
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    titlebarAppearsTransparent = true
    titleVisibility = .hidden
    isMovableByWindowBackground = true
    title = "QuickPush"
    isReleasedWhenClosed = false
    animationBehavior = .utilityWindow

    // Minimum size to keep the UI usable
    minSize = NSSize(width: 420, height: 460)

    // Restore saved position or center on screen
    if let frameString = UserDefaults.standard.string(forKey: "FloatingPanelFrame"),
       !frameString.isEmpty {
      setFrame(NSRectFromString(frameString), display: true)
    } else {
      center()
    }
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  /// Save the panel frame whenever it moves or resizes.
  func saveFrame() {
    UserDefaults.standard.set(NSStringFromRect(frame), forKey: "FloatingPanelFrame")
  }

  override func close() {
    saveFrame()
    // Route through the WindowManager so it can cleanly detach
    // SwiftUI views before the window hides.
    if let onClose {
      onClose()
    } else {
      super.close()
    }
  }
}
