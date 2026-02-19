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
        .miniaturizable,
        .resizable,
      ],
      backing: .buffered,
      defer: false
    )

    level = .floating
    isFloatingPanel = true
    hidesOnDeactivate = false
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    titlebarAppearsTransparent = false
    titleVisibility = .hidden
    isMovableByWindowBackground = true
    title = "Quick Push"
    isReleasedWhenClosed = false
    animationBehavior = .utilityWindow
    isOpaque = false
    backgroundColor = .clear

    // Frosted glass background
    let blurView = NSVisualEffectView()
    blurView.material = .hudWindow
    blurView.blendingMode = .behindWindow
    blurView.state = .active
    contentView = blurView

    // Custom icon + title placed directly in the titlebar
    if let titlebarView = standardWindowButton(.closeButton)?.superview {
      let iconView = NSImageView()
      let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
      iconView.image = NSImage(
        systemSymbolName: "bolt.brakesignal",
        accessibilityDescription: "Quick Push"
      )?.withSymbolConfiguration(config)
      iconView.contentTintColor = .secondaryLabelColor
      iconView.translatesAutoresizingMaskIntoConstraints = false

      let label = NSTextField(labelWithString: "Quick Push")
      label.font = .titleBarFont(ofSize: 13)
      label.textColor = .labelColor
      label.translatesAutoresizingMaskIntoConstraints = false

      let stack = NSStackView(views: [iconView, label])
      stack.orientation = .horizontal
      stack.spacing = 4
      stack.alignment = .centerY
      stack.translatesAutoresizingMaskIntoConstraints = false

      titlebarView.addSubview(stack)
      NSLayoutConstraint.activate([
        stack.centerYAnchor.constraint(equalTo: titlebarView.centerYAnchor),
        stack.centerXAnchor.constraint(equalTo: titlebarView.centerXAnchor),
      ])
    }

    // Minimum size to keep the UI usable
    minSize = NSSize(width: 520, height: 460)

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
