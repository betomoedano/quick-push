//
//  SaveTokenSheet.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

/// Modal sheet for saving a push token with a user-defined label.
struct SaveTokenSheet: View {
  let token: String
  let onSave: (String) -> Void
  var warningText: String = "Expo push tokens may change when you reinstall the app on your device."
  @Environment(\.dismiss) private var dismiss
  @State private var label: String = ""

  var body: some View {
    VStack(spacing: 16) {
      // Header
      HStack {
        Text("Save Token")
          .font(.headline)
        Spacer()
        Button("Cancel") { dismiss() }
          .keyboardShortcut(.cancelAction)
      }

      // Explanatory text
      Text("Save this token for future sessions so you don't have to paste it again.")
        .font(.callout)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)

      // Token preview (read-only)
      Text(token)
        .font(.system(.caption, design: .monospaced))
        .foregroundColor(.secondary)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(
          RoundedRectangle(cornerRadius: 6)
            .stroke(Color.secondary.opacity(0.2))
        )
        .cornerRadius(6)

      // Label input
      VStack(alignment: .leading, spacing: 4) {
        Text("Label:")
          .font(.subheadline)
        TextField("e.g. iPhone 17 Pro, Android Pixel", text: $label)
          .textFieldStyle(.roundedBorder)
      }

      // Warning note
      HStack(alignment: .top, spacing: 6) {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundColor(.orange)
          .font(.caption)
        Text(warningText)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // Action buttons
      HStack {
        Spacer()
        Button("Save") {
          onSave(label.trimmingCharacters(in: .whitespaces))
          dismiss()
        }
        .buttonStyle(.borderedProminent)
        .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding()
    .frame(width: 400)
  }
}
