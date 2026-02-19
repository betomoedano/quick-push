//
//  ExpoCurlCommandView.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

/// Sheet that displays a copyable curl command for the current Expo push notification.
struct ExpoCurlCommandView: View {
  let notification: PushNotification
  let accessToken: String?
  @Environment(\.dismiss) private var dismiss
  @State private var copied = false

  private var curlCommand: String {
    buildCurlCommand()
  }

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
      }
    }
    .padding()
    .frame(minWidth: 450, minHeight: 300)
  }

  // MARK: - Build cURL

  private func buildCurlCommand() -> String {
    var lines: [String] = []
    lines.append("curl -X POST https://exp.host/--/api/v2/push/send \\")
    lines.append("  -H \"Content-Type: application/json\" \\")
    lines.append("  -H \"Accept: application/json\" \\")
    lines.append("  -H \"Host: exp.host\" \\")

    if let token = accessToken, !token.isEmpty {
      lines.append("  -H \"Authorization: Bearer \(token)\" \\")
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let jsonData = try? encoder.encode(notification),
       let jsonString = String(data: jsonData, encoding: .utf8) {
      lines.append("  -d '\(jsonString)'")
    }

    return lines.joined(separator: "\n")
  }
}
