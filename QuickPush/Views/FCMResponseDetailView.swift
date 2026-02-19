//
//  FCMResponseDetailView.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

/// Sheet that displays the full FCM response diagnostics after a send attempt.
struct FCMResponseDetailView: View {
  let response: FCMResponse?
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text("FCM Response")
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

          Group {
            FCMResponseRow(label: "Status", value: "\(response.statusCode)")
            if let messageId = response.messageId {
              FCMResponseRow(label: "Message ID", value: messageId)
            }
            if let errorCode = response.errorCode {
              FCMResponseRow(label: "Error Code", value: errorCode, isError: true)
            }
            if let errorMessage = response.errorMessage {
              FCMResponseRow(label: "Error Message", value: errorMessage, isError: true)
            }
            FCMResponseRow(label: "Project ID", value: response.projectId)
            FCMResponseRow(label: "Timestamp", value: "\(response.timestamp) (Unix sec)")
          }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.secondary.opacity(0.2))
        )

        // Troubleshooting tips
        if let errorCode = response.errorCode {
          fcmTroubleshootingTip(for: errorCode)
        } else if let errorMessage = response.errorMessage, !response.isSuccess {
          fcmTroubleshootingTip(for: errorMessage)
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
  private func fcmTroubleshootingTip(for code: String) -> some View {
    let tip: String? = switch code {
    case "INVALID_ARGUMENT":
      "The request payload is invalid. Check that the FCM registration token is correct and the message payload is well-formed."
    case "NOT_FOUND", "UNREGISTERED":
      "The FCM registration token is no longer valid. The device may have uninstalled the app or the token has expired. Remove this token from your records."
    case "SENDER_ID_MISMATCH":
      "The token was registered with a different sender (project). Ensure you are using the correct Firebase project and service account."
    case "QUOTA_EXCEEDED":
      "Sending rate exceeded. Slow down your message sending rate and retry with exponential backoff."
    case "UNAVAILABLE":
      "The FCM service is temporarily unavailable. Retry with exponential backoff."
    case "INTERNAL":
      "An internal error occurred on the FCM server. Retry with exponential backoff."
    default:
      nil
    }

    if let tip {
      FCMTipBox(icon: "lightbulb.fill", color: .yellow, text: tip)
    }
  }
}

private struct FCMTipBox: View {
  let icon: String
  let color: Color
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: icon)
        .foregroundColor(color)
      Text(.init(text))
        .font(.callout)
        .foregroundColor(.secondary)
    }
    .padding(10)
    .background(color.opacity(0.1))
    .cornerRadius(6)
  }
}

private struct FCMResponseRow: View {
  let label: String
  let value: String
  var isError: Bool = false

  var body: some View {
    HStack(alignment: .top) {
      Text(label)
        .foregroundColor(.secondary)
        .frame(width: 110, alignment: .trailing)
      Text(value)
        .fontWeight(isError ? .semibold : .regular)
        .foregroundColor(isError ? .red : .primary)
        .textSelection(.enabled)
      Spacer()
    }
    .padding(.vertical, 3)
  }
}
