//
//  APNsConfigurationView.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

struct APNsConfigurationView: View {
  @Bindable var config: APNsConfigStore
  @State private var isExpanded: Bool = true

  private var isValid: Bool {
    !config.teamId.isEmpty && !config.keyId.isEmpty && !config.bundleId.isEmpty && config.hasP8Key
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button(action: { withAnimation { isExpanded.toggle() } }) {
        HStack {
          Text("APNs Configuration")
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
            Text("Team ID:")
              .frame(width: 70, alignment: .leading)
            TextField("e.g. A1B2C3D4E5", text: $config.teamId)
              .textFieldStyle(.roundedBorder)
          }

          HStack {
            Text("Key ID:")
              .frame(width: 70, alignment: .leading)
            TextField("e.g. ABCDE12345", text: $config.keyId)
              .textFieldStyle(.roundedBorder)
          }

          HStack {
            Text("Bundle ID:")
              .frame(width: 70, alignment: .leading)
            TextField("e.g. com.example.app", text: $config.bundleId)
              .textFieldStyle(.roundedBorder)
          }

          HStack {
            Text(".p8 Key:")
              .frame(width: 70, alignment: .leading)
            if let name = config.p8FileName, config.hasP8Key {
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
              config.selectP8File()
            }
            .controlSize(.small)
          }

          HStack {
            Text("Environment:")
            Picker("", selection: $config.environment) {
              Text("Sandbox").tag(APNsEnvironment.sandbox)
              Text("Production").tag(APNsEnvironment.production)
            }
            .pickerStyle(.segmented)
          }
        }
        .padding(.leading, 4)
      }
    }
  }
}
