//
//  ExpoResponseDetailView.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

/// Sheet that displays the full Expo Push API response in a developer-friendly way.
struct ExpoResponseDetailView: View {
  let response: PushResponse?
  let httpStatusCode: Int?
  let rawJSON: String?
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Response")
          .font(.headline)
        Spacer()
        Button("Close") { dismiss() }
          .keyboardShortcut(.cancelAction)
      }

      if let response {
        // Top-level API errors (e.g. UNAUTHORIZED)
        if let errors = response.errors, !errors.isEmpty {
          apiErrorsSection(errors)
        }

        // Per-ticket results
        if let tickets = response.data, !tickets.isEmpty {
          ticketsSection(tickets)
        }

        // Raw JSON
        if let rawJSON, !rawJSON.isEmpty {
          rawJSONSection(rawJSON)
        }

        HStack {
          Button("Copy Response") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(rawJSON ?? "", forType: .string)
          }
          .help("Copy raw JSON response to clipboard")
          .disabled(rawJSON == nil)
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

  // MARK: - Sections

  @ViewBuilder
  private func apiErrorsSection(_ errors: [PushResponse.PushError]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(.red)
          .font(.title2)
        Text("API Error")
          .font(.title3)
          .fontWeight(.semibold)
        if let statusCode = httpStatusCode {
          Text("(\(statusCode))")
            .foregroundColor(.secondary)
        }
        Spacer()
      }

      ForEach(Array(errors.enumerated()), id: \.offset) { _, error in
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(error.code)
              .font(.system(.body, design: .monospaced))
              .fontWeight(.semibold)
              .foregroundColor(.red)
            if error.isTransient == true {
              Text("(transient)")
                .font(.caption)
                .foregroundColor(.orange)
            }
          }
          Text(error.message)
            .font(.callout)
            .foregroundColor(.secondary)
            .textSelection(.enabled)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08))
        .cornerRadius(6)
      }
    }
  }

  @ViewBuilder
  private func ticketsSection(_ tickets: [PushResponse.PushTicket]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      let successCount = tickets.filter { $0.status == "ok" }.count
      let errorCount = tickets.filter { $0.status == "error" }.count

      HStack(spacing: 8) {
        Image(systemName: errorCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
          .foregroundColor(errorCount == 0 ? .green : .orange)
          .font(.title2)
        Text(errorCount == 0 ? "All Delivered" : "\(successCount) OK, \(errorCount) Failed")
          .font(.title3)
          .fontWeight(.semibold)
        if let statusCode = httpStatusCode {
          Text("(\(statusCode))")
            .foregroundColor(.secondary)
        }
        Spacer()
      }

      ForEach(Array(tickets.enumerated()), id: \.offset) { index, ticket in
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Ticket \(index + 1)")
              .font(.subheadline)
              .fontWeight(.medium)
            Circle()
              .fill(ticket.status == "ok" ? Color.green : Color.red)
              .frame(width: 8, height: 8)
            Text(ticket.status)
              .font(.system(.caption, design: .monospaced))
            Spacer()
          }

          if let id = ticket.id {
            HStack(spacing: 4) {
              Text("ID:")
                .foregroundColor(.secondary)
                .font(.caption)
              Text(id)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
            }
          }

          if let message = ticket.message {
            Text(message)
              .font(.callout)
              .foregroundColor(.red)
              .textSelection(.enabled)
          }

          if let details = ticket.details {
            ForEach(Array(details.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
              HStack(spacing: 4) {
                Text("\(key):")
                  .foregroundColor(.secondary)
                  .font(.caption)
                Text(value)
                  .font(.system(.caption, design: .monospaced))
                  .textSelection(.enabled)
              }
            }
          }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ticket.status == "ok" ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
        .cornerRadius(6)
      }
    }
  }

  @ViewBuilder
  private func rawJSONSection(_ json: String) -> some View {
    DisclosureGroup("Raw JSON") {
      ScrollView {
        Text(json)
          .font(.system(.caption, design: .monospaced))
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxHeight: 150)
      .padding(8)
      .background(Color(nsColor: .controlBackgroundColor))
      .cornerRadius(6)
    }
  }
}
