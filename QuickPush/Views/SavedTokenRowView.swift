//
//  SavedTokenRowView.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

/// Compact row display for a saved push token, showing label and token.
struct SavedTokenRowView: View {
  let savedToken: SavedToken
  let onToggle: () -> Void
  let onCopy: () -> Void
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      // Enable/disable toggle
      Button(action: onToggle) {
        Image(systemName: savedToken.isEnabled ? "checkmark.circle.fill" : "circle")
          .foregroundColor(savedToken.isEnabled ? .accentColor : .secondary)
          .font(.system(size: 14))
      }
      .buttonStyle(.plain)
      .help(savedToken.isEnabled ? "Disable this token" : "Enable this token")

      VStack(alignment: .leading, spacing: 2) {
        Text(savedToken.label)
          .font(.subheadline)
          .fontWeight(.medium)
          .lineLimit(1)
        Text(savedToken.token)
          .font(.system(.caption2, design: .monospaced))
          .foregroundColor(.secondary)
          .lineLimit(1)
          .truncationMode(.middle)
      }

      Spacer()

      // Copy token button
      Button(action: onCopy) {
        Image(systemName: "doc.on.doc")
          .foregroundColor(.secondary)
      }
      .buttonStyle(.plain)
      .help("Copy token to clipboard")

      // Remove from saved button
      Button(action: onRemove) {
        Image(systemName: "bookmark.slash.fill")
          .foregroundColor(.orange)
      }
      .buttonStyle(.plain)
      .help("Remove from saved tokens")
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 8)
    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    .cornerRadius(6)
    .opacity(savedToken.isEnabled ? 1 : 0.5)
  }
}
