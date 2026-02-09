//
//  SecurityBookmarkManager.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import Foundation
import AppKit

/// Manages selection and persistent storage of the .p8 APNs auth key.
///
/// Instead of relying on security-scoped bookmarks (which fail in sandbox
/// and break across Xcode rebuilds), we read the file contents once when
/// selected and store them directly in UserDefaults.
class SecurityBookmarkManager {
  static let shared = SecurityBookmarkManager()

  private let p8ContentsKey = "p8FileContents"
  private let p8FilenameKey = "p8FileName"

  // MARK: - File Picker

  func selectP8File(completion: @escaping (String?, String?) -> Void) {
    let panel = NSOpenPanel()
    panel.title = "Select APNs Auth Key (.p8)"
    panel.allowedContentTypes = [.init(filenameExtension: "p8")!]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false

    panel.begin { response in
      guard response == .OK, let url = panel.url else {
        completion(nil, nil)
        return
      }

      // Read the file contents immediately while NSOpenPanel access is active.
      let contents = try? String(contentsOf: url, encoding: .utf8)
      let filename = url.lastPathComponent

      if let contents {
        self.saveP8(contents: contents, filename: filename)
      }

      completion(contents, filename)
    }
  }

  // MARK: - Storage

  func saveP8(contents: String, filename: String) {
    UserDefaults.standard.set(contents, forKey: p8ContentsKey)
    UserDefaults.standard.set(filename, forKey: p8FilenameKey)
  }

  func storedP8Contents() -> String? {
    UserDefaults.standard.string(forKey: p8ContentsKey)
  }

  func storedP8Filename() -> String? {
    UserDefaults.standard.string(forKey: p8FilenameKey)
  }

  func clearStoredP8() {
    UserDefaults.standard.removeObject(forKey: p8ContentsKey)
    UserDefaults.standard.removeObject(forKey: p8FilenameKey)
  }
}
