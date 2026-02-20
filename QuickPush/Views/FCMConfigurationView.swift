//
//  FCMConfigurationView.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

struct FCMConfigurationView: View {
  @Bindable var config: FCMConfigStore

  private var isValid: Bool {
    !config.projectId.isEmpty && !config.clientEmail.isEmpty && config.hasServiceAccount
  }

  @State private var isExpanded: Bool = false

  init(config: FCMConfigStore) {
    self.config = config
    // Start collapsed if already configured, expanded if not yet set up
    _isExpanded = State(initialValue: !config.hasServiceAccount)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button(action: { withAnimation { isExpanded.toggle() } }) {
        HStack {
          Text("FCM Configuration")
            .font(.subheadline)
            .fontWeight(.medium)
          Spacer()
          Circle()
            .fill(isValid ? Color.green : Color.orange)
            .frame(width: 8, height: 8)
          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .foregroundColor(.secondary)
        }
      }
      .buttonStyle(.plain)

      if isExpanded {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Service Account:")
              .frame(width: 110, alignment: .leading)
            if let name = config.serviceAccountFilename, config.hasServiceAccount {
              Text(name)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            } else {
              Text("No file selected")
                .foregroundColor(.secondary)
            }
            Spacer()
            Button("Browse...") {
              config.selectServiceAccountFile()
            }
            .controlSize(.small)
          }

          if let error = config.fileError {
            HStack(alignment: .top, spacing: 6) {
              Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.caption)
              Text(error)
                .font(.caption)
                .foregroundColor(.orange)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(6)
          }

          HStack {
            Text("Project ID:")
              .frame(width: 110, alignment: .leading)
            TextField("e.g. my-app-12345", text: $config.projectId)
              .textFieldStyle(.roundedBorder)
          }

          HStack {
            Text("Client Email:")
              .frame(width: 110, alignment: .leading)
            TextField("service-account@project.iam.gserviceaccount.com", text: $config.clientEmail)
              .textFieldStyle(.roundedBorder)
              .foregroundColor(.secondary)
          }
        }
        .padding(.leading, 4)
      }
    }
  }
}
