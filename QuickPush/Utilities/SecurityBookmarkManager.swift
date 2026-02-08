//
//  SecurityBookmarkManager.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import Foundation
import AppKit

class SecurityBookmarkManager {
  static let shared = SecurityBookmarkManager()
  private let bookmarkKey = "p8FileBookmark"

  func selectP8File(completion: @escaping (URL?) -> Void) {
    let panel = NSOpenPanel()
    panel.title = "Select APNs Auth Key (.p8)"
    panel.allowedContentTypes = [.init(filenameExtension: "p8")!]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false

    panel.begin { response in
      guard response == .OK, let url = panel.url else {
        completion(nil)
        return
      }

      self.saveBookmark(for: url)
      completion(url)
    }
  }

  func saveBookmark(for url: URL) {
    do {
      let bookmarkData = try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
    } catch {
      print("Failed to save bookmark: \(error)")
    }
  }

  func resolveBookmark() -> URL? {
    guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
      return nil
    }

    do {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      if isStale {
        saveBookmark(for: url)
      }

      return url
    } catch {
      print("Failed to resolve bookmark: \(error)")
      return nil
    }
  }

  func readP8FileContents(from url: URL) -> String? {
    let hasAccess = url.startAccessingSecurityScopedResource()
    defer {
      if hasAccess { url.stopAccessingSecurityScopedResource() }
    }

    // Try reading regardless — NSOpenPanel grants access during the session
    // even if the security-scoped bookmark failed to save
    return try? String(contentsOf: url, encoding: .utf8)
  }
}
