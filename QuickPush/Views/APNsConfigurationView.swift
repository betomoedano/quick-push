//
//  APNsConfigurationView.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

struct APNsConfigurationView: View {
  @Bindable var viewModel: LiveActivityViewModel
  @State private var isExpanded: Bool = true

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button(action: { withAnimation { isExpanded.toggle() } }) {
        HStack {
          Text("APNs Configuration")
            .font(.subheadline)
            .fontWeight(.medium)
          Spacer()
          Circle()
            .fill(viewModel.apnsConfiguration.isValid ? Color.green : Color.orange)
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
            TextField("e.g. A1B2C3D4E5", text: $viewModel.teamId)
              .textFieldStyle(.roundedBorder)
          }

          HStack {
            Text("Key ID:")
              .frame(width: 70, alignment: .leading)
            TextField("e.g. ABCDE12345", text: $viewModel.keyId)
              .textFieldStyle(.roundedBorder)
          }

          HStack {
            Text("Bundle ID:")
              .frame(width: 70, alignment: .leading)
            TextField("e.g. com.example.app", text: $viewModel.bundleId)
              .textFieldStyle(.roundedBorder)
          }

          HStack {
            Text(".p8 Key:")
              .frame(width: 70, alignment: .leading)
            if let name = viewModel.p8FileName, viewModel.hasP8Key {
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
              viewModel.selectP8File()
            }
            .controlSize(.small)
          }

          HStack {
            Text("Attributes Type:")
              .frame(width: 95, alignment: .leading)
            TextField("e.g. MyWidget.LiveActivityAttributes", text: $viewModel.attributesType)
              .textFieldStyle(.roundedBorder)
            HelpButton(helpText: "Must match the fully module-qualified Swift type name of your ActivityAttributes struct. Run this in your iOS app to get the exact value:\n\nprint(String(reflecting: LiveActivityAttributes.self))\n\nCommon formats:\n• MyWidgetExtension.LiveActivityAttributes\n• LiveActivityAttributes\n\nA mismatch causes iOS to silently drop the push even if APNs returns 200.")
          }

          HStack {
            Text("Environment:")
            Picker("", selection: $viewModel.environment) {
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
