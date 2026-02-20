//
//  ExpoReceiptView.swift
//  QuickPush
//
//  Created by beto on 2/20/26.
//

import SwiftUI

struct ExpoReceiptView: View {
  let initialTicketIds: [String]
  let accessToken: String?
  @Environment(\.dismiss) private var dismiss

  @State private var ids: [String]
  @State private var isLoading: Bool = false
  @State private var result: PushNotificationService.ReceiptResult?
  @State private var errorMessage: String?

  init(ticketIds: [String], accessToken: String?) {
    self.initialTicketIds = ticketIds
    self.accessToken = accessToken
    _ids = State(initialValue: ticketIds.isEmpty ? [""] : ticketIds)
  }

  var body: some View {
    VStack(spacing: 12) {
      // Header
      HStack {
        Text("Check Receipts")
          .font(.headline)
        Spacer()
        Button("Close") { dismiss() }
          .keyboardShortcut(.cancelAction)
      }

      // IDs input list
      VStack(alignment: .leading, spacing: 8) {
        Text("Ticket IDs:")
          .font(.subheadline)

        ForEach(ids.indices, id: \.self) { index in
          HStack(spacing: 8) {
            TextField("Ticket ID (e.g. abc123...)", text: $ids[index])
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .font(.system(.caption, design: .monospaced))

            Button(action: {
              if let clip = NSPasteboard.general.string(forType: .string) {
                ids[index] = clip.trimmingCharacters(in: .whitespacesAndNewlines)
              }
            }) {
              Image(systemName: "doc.on.clipboard")
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Paste from clipboard")

            if ids.count > 1 {
              Button(action: { ids.remove(at: index) }) {
                Image(systemName: "minus.circle.fill")
                  .foregroundColor(.red)
              }
              .buttonStyle(.plain)
            }
          }
        }

        Button(action: { ids.append("") }) {
          HStack {
            Image(systemName: "plus.circle.fill")
            Text("Add ID")
          }
        }
        .buttonStyle(.borderless)
      }

      // Check button + error
      HStack {
        if let errorMessage {
          Text(errorMessage)
            .font(.caption)
            .foregroundColor(.red)
        }
        Spacer()
        Button {
          checkReceipts()
        } label: {
          if isLoading {
            HStack(spacing: 6) {
              ProgressView()
                .scaleEffect(0.6)
                .frame(width: 14, height: 14)
              Text("Checking…")
            }
          } else {
            Text("Check Receipts")
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(validIds.isEmpty || isLoading)
      }

      Divider()

      // Results
      if let result {
        resultsSection(result)
      } else {
        Text("Enter ticket IDs and tap \"Check Receipts\".")
          .font(.callout)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      Spacer()
    }
    .padding()
    .frame(minWidth: 460, minHeight: 340)
  }

  // MARK: - Results

  @ViewBuilder
  private func resultsSection(_ result: PushNotificationService.ReceiptResult) -> some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack(alignment: .leading, spacing: 10) {
        // API-level errors
        if let errors = result.response.errors, !errors.isEmpty {
          VStack(alignment: .leading, spacing: 6) {
            Label("API Error", systemImage: "xmark.circle.fill")
              .foregroundColor(.red)
              .font(.subheadline.weight(.semibold))

            ForEach(Array(errors.enumerated()), id: \.offset) { _, err in
              VStack(alignment: .leading, spacing: 2) {
                Text(err.code)
                  .font(.system(.caption, design: .monospaced))
                  .fontWeight(.semibold)
                  .foregroundColor(.red)
                Text(err.message)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              .padding(8)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(Color.red.opacity(0.08))
              .cornerRadius(6)
            }
          }
        }

        // Per-receipt results
        if let receipts = result.response.data, !receipts.isEmpty {
          ForEach(receipts.sorted(by: { $0.key < $1.key }), id: \.key) { id, receipt in
            receiptRow(id: id, receipt: receipt)
          }
        } else if result.response.errors == nil {
          Text("No receipts returned for the given IDs. They may be expired or invalid.")
            .font(.callout)
            .foregroundColor(.secondary)
        }

        // Raw JSON disclosure
        if let raw = result.rawJSON, !raw.isEmpty {
          DisclosureGroup("Raw JSON") {
            ScrollView {
              Text(raw)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 140)
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func receiptRow(id: String, receipt: ReceiptResponse.PushReceipt) -> some View {
    let isOk = receipt.status == "ok"
    let errorCode = receipt.details?.error

    VStack(alignment: .leading, spacing: 6) {
      // Status badge + ID
      HStack(spacing: 6) {
        Circle()
          .fill(isOk ? Color.green : Color.red)
          .frame(width: 8, height: 8)
        Text(receipt.status)
          .font(.system(.caption, design: .monospaced))
          .fontWeight(.semibold)
          .foregroundColor(isOk ? .green : .red)
        Spacer()
        Text(id)
          .font(.system(.caption2, design: .monospaced))
          .foregroundColor(.secondary)
          .textSelection(.enabled)
          .lineLimit(1)
          .truncationMode(.middle)
      }

      // "ok" informational note
      if isOk {
        Label(
          "\"ok\" means FCM/APNs accepted the notification — not that the device displayed it.",
          systemImage: "info.circle"
        )
        .font(.caption)
        .foregroundColor(.secondary)
      }

      // Error message
      if let message = receipt.message {
        Text(message)
          .font(.caption)
          .foregroundColor(.red)
          .textSelection(.enabled)
      }

      // Error code + actionable guidance
      if let code = errorCode {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 4) {
            Text("Error code:")
              .font(.caption)
              .foregroundColor(.secondary)
            Text(code)
              .font(.system(.caption, design: .monospaced))
              .fontWeight(.semibold)
              .foregroundColor(.orange)
          }
          Text(guidance(for: code))
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(6)
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(isOk ? Color.green.opacity(0.07) : Color.red.opacity(0.07))
    .cornerRadius(8)
  }

  // MARK: - Helpers

  private var validIds: [String] {
    ids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
  }

  private func checkReceipts() {
    errorMessage = nil
    isLoading = true
    result = nil

    PushNotificationService.shared.checkReceipts(
      ids: validIds,
      accessToken: accessToken
    ) { outcome in
      DispatchQueue.main.async {
        isLoading = false
        switch outcome {
        case .success(let receiptResult):
          result = receiptResult
        case .failure(let error):
          errorMessage = error.localizedDescription
        }
      }
    }
  }

  private func guidance(for errorCode: String) -> String {
    switch errorCode {
    case "DeviceNotRegistered":
      return "Remove this token — the device has opted out or uninstalled the app."
    case "MessageTooBig":
      return "Reduce the notification payload size."
    case "MessageRateExceeded":
      return "Back off — too many messages have been sent to this device recently."
    case "MismatchSenderId":
      return "This token belongs to a different FCM sender ID. Check your push credentials."
    case "InvalidCredentials":
      return "Your push credentials are invalid. Reconfigure them in the EAS Dashboard."
    default:
      return "Check the Expo push notifications documentation for details on this error."
    }
  }
}
