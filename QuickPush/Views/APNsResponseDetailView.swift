//
//  APNsResponseDetailView.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

/// Sheet that displays the full APNs response diagnostics after a send attempt.
struct APNsResponseDetailView: View {
  let response: APNsResponse?
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text("APNs Response")
          .font(.headline)
        Spacer()
        Button("Close") { dismiss() }
          .keyboardShortcut(.cancelAction)
      }

      if let response {
        VStack(alignment: .leading, spacing: 0) {
          // Status header
          HStack(spacing: 8) {
            Image(systemName: response.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
              .foregroundColor(response.isSuccess ? .green : .red)
              .font(.title2)
            Text(response.isSuccess ? "Push Accepted" : "Push Rejected")
              .font(.title3)
              .fontWeight(.semibold)
            Spacer()
          }
          .padding(.bottom, 12)

          // Diagnostic rows
          Group {
            ResponseRow(label: "Status", value: "\(response.statusCode)")
            if let reason = response.reason {
              ResponseRow(label: "Reason", value: reason, isError: true)
            }
            ResponseRow(label: "Event", value: response.event)
            ResponseRow(label: "Environment", value: "\(response.environment.rawValue.capitalized)")
            ResponseRow(label: "Hostname", value: response.hostname)
            ResponseRow(label: "Topic", value: response.topic)
            if let attributesType = response.attributesType {
              ResponseRow(label: "Attributes Type", value: attributesType, isHighlighted: true)
            }
            ResponseRow(label: "Timestamp", value: "\(response.timestamp) (Unix sec)")
            if let apnsId = response.apnsId {
              ResponseRow(label: "apns-id", value: apnsId)
            }
            if let apnsUniqueId = response.apnsUniqueId {
              ResponseRow(label: "apns-unique-id", value: apnsUniqueId)
            }
          }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.secondary.opacity(0.2))
        )

        // Troubleshooting tips for common errors
        if let reason = response.reason {
          troubleshootingTip(for: reason)
        }

        // Warn about silent drops on 200 with start event
        if response.isSuccess && response.event == "start" {
          successButNoActivityTip(attributesType: response.attributesType)
        }

        HStack {
          Button("Copy Diagnostics") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(response.diagnosticDetails, forType: .string)
          }
          .help("Copy full diagnostic info to clipboard")
          Spacer()
        }
      } else {
        Text("No response yet. Send a push first.")
          .foregroundColor(.secondary)
      }

      Spacer()
    }
    .padding()
    .frame(minWidth: 420, minHeight: 300)
  }

  @ViewBuilder
  private func troubleshootingTip(for reason: String) -> some View {
    let tip: String? = switch reason {
    case "BadDeviceToken":
      "The token is invalid. Check: wrong environment (sandbox vs production), token is stale, or token format is incorrect."
    case "DeviceTokenNotForTopic":
      "The device token doesn't match the topic (bundle ID). Verify your Bundle ID is correct and the token was generated for this app."
    case "Unregistered":
      "The token is no longer valid. The device may have uninstalled the app or the token has expired."
    case "TopicDisallowed":
      "Push notifications are not allowed for this topic. Check your provisioning profile and entitlements."
    case "InvalidProviderToken":
      "The JWT token is invalid. Verify your Team ID, Key ID, and .p8 key file."
    case "ExpiredProviderToken":
      "The JWT token has expired. It will be refreshed on the next send."
    case "MissingTopic":
      "The apns-topic header is missing. This is a QuickPush bug — please report it."
    default:
      nil
    }

    if let tip {
      TipBox(icon: "lightbulb.fill", color: .yellow, text: tip)
    }
  }

  private func successButNoActivityTip(attributesType: String?) -> some View {
    let tip = Self.buildSuccessTip(attributesType: attributesType)
    return TipBox(
      icon: "exclamationmark.triangle.fill",
      color: .orange,
      text: tip
    )
  }

  private static func buildSuccessTip(attributesType: String?) -> String {
    let attrType = attributesType ?? "unknown"
    let needsModulePrefix = !attrType.contains(".")

    var lines = """
    APNs returned 200 but the Live Activity didn't appear? Common causes:

    1. **attributes-type mismatch** — iOS expects the module-qualified name.
       Current value: "\(attrType)"
    """
    if needsModulePrefix {
      lines += "\n   Try: \"YourWidgetTarget.\(attrType)\""
    }
    lines += """

    2. **Timestamp too far from "now"** — must be current Unix seconds.

    3. **Token/environment mismatch** — sandbox token with production, or vice versa.

    To find the exact attributes-type, add this to your iOS app:
    `print(String(reflecting: YourAttributes.self))`
    """
    return lines
  }
}

/// Styled tip box used for troubleshooting hints.
private struct TipBox: View {
  let icon: String
  let color: Color
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: icon)
        .foregroundColor(color)
      // Use .init() to enable Markdown rendering in the string
      Text(.init(text))
        .font(.callout)
        .foregroundColor(.secondary)
    }
    .padding(10)
    .background(color.opacity(0.1))
    .cornerRadius(6)
  }
}

/// A single label–value row in the response detail view.
private struct ResponseRow: View {
  let label: String
  let value: String
  var isError: Bool = false
  var isHighlighted: Bool = false

  var body: some View {
    HStack(alignment: .top) {
      Text(label)
        .foregroundColor(.secondary)
        .frame(width: 110, alignment: .trailing)
      Text(value)
        .fontWeight((isError || isHighlighted) ? .semibold : .regular)
        .foregroundColor(isError ? .red : isHighlighted ? .orange : .primary)
        .textSelection(.enabled)
      Spacer()
    }
    .padding(.vertical, 3)
  }
}
