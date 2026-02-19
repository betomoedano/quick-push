//
//  FCMCurlCommandView.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

/// Sheet that displays a copyable FCM curl command.
struct FCMCurlCommandView: View {
  let curlCommand: String
  @Environment(\.dismiss) private var dismiss
  @State private var copied = false

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text("cURL Command")
          .font(.headline)
        Spacer()
        Button("Close") { dismiss() }
          .keyboardShortcut(.cancelAction)
      }

      ScrollView {
        Text(curlCommand)
          .font(.system(.body, design: .monospaced))
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(8)
      }
      .background(Color(nsColor: .controlBackgroundColor))
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.secondary.opacity(0.2))
      )

      HStack {
        Button(copied ? "Copied!" : "Copy") {
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(curlCommand, forType: .string)
          copied = true
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
          }
        }
        .help("Copy curl command to clipboard")

        Spacer()

        Text("Replace <ACCESS_TOKEN> with a valid OAuth 2.0 bearer token")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding()
    .frame(minWidth: 500, minHeight: 300)
  }
}
