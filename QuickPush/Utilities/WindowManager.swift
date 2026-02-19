//
//  WindowManager.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

/// Manages the floating "pinned" window and the global keyboard shortcut.
@Observable
final class WindowManager {

  /// Whether the floating panel is currently visible.
  private(set) var isPinned: Bool = false

  private var panel: FloatingPanel?
  private var globalMonitor: Any?
  private var localMonitor: Any?
  private var hotkeyRegistered = false

  deinit {
    removeHotkey()
  }

  /// Call once after app has finished launching (e.g. from onAppear).
  func startMonitoring() {
    guard !hotkeyRegistered else { return }
    hotkeyRegistered = true
    registerHotkey()
  }

  // MARK: - Pin / Unpin

  func togglePin() {
    if isPinned {
      unpin()
    } else {
      pin()
    }
  }

  func pin() {
    guard !isPinned else { return }

    // Dismiss the MenuBarExtra popover by closing every visible window
    // that isn't our floating panel. The popover is backed by an internal
    // NSWindow — ordering it out hides it without destroying it.
    for window in NSApp.windows where window !== panel && window.isVisible {
      window.orderOut(nil)
    }

    // Create the floating panel if needed
    if panel == nil {
      let rect = NSRect(x: 0, y: 0, width: 420, height: 500)
      let newPanel = FloatingPanel(contentRect: rect)
      newPanel.onClose = { [weak self] in
        self?.unpin()
      }
      panel = newPanel
    }

    // Host the SwiftUI content inside the panel
    let content = MainContentView()
      .environment(self)

    let hostingView = NSHostingView(rootView: content)
    hostingView.sizingOptions = [.minSize]
    panel?.contentView = hostingView

    // Show the panel after a brief delay so the popover finishes closing.
    DispatchQueue.main.async { [weak self] in
      guard let self, let panel = self.panel else { return }

      // Temporarily become a regular app so macOS lets us show a window,
      // then switch back to accessory so we don't linger in the Dock.
      NSApp.setActivationPolicy(.regular)
      panel.makeKeyAndOrderFront(nil)

      DispatchQueue.main.async {
        NSApp.setActivationPolicy(.accessory)
      }

      self.isPinned = true
    }
  }

  func unpin() {
    guard isPinned else { return }

    guard let panel else {
      isPinned = false
      return
    }

    panel.saveFrame()

    // Detach the SwiftUI hosting view FIRST so it doesn't try to
    // re-render while the window disappears underneath it.
    panel.contentView = nil

    // Now hide the panel safely.
    panel.orderOut(nil)

    isPinned = false
  }

  /// Called when the user clicks the menu bar icon while the panel is pinned.
  func bringPanelToFront() {
    guard isPinned, let panel else { return }
    panel.orderFrontRegardless()
    panel.makeKey()
  }

  // MARK: - Global Keyboard Shortcut (Cmd+Shift+P)

  private func registerHotkey() {
    // Global monitor – fires when our app is NOT focused
    globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
      self?.handleHotkey(event)
    }

    // Local monitor – fires when our app IS focused
    localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if self?.handleHotkey(event) == true {
        return nil // swallow the event
      }
      return event
    }
  }

  private func removeHotkey() {
    if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
    if let localMonitor { NSEvent.removeMonitor(localMonitor) }
    globalMonitor = nil
    localMonitor = nil
  }

  /// Returns `true` if the event matched our shortcut and was handled.
  @discardableResult
  private func handleHotkey(_ event: NSEvent) -> Bool {
    // Cmd + Shift + P
    guard event.modifierFlags.contains([.command, .shift]),
          event.charactersIgnoringModifiers?.lowercased() == "p" else {
      return false
    }

    DispatchQueue.main.async { [weak self] in
      self?.togglePin()
    }
    return true
  }
}
