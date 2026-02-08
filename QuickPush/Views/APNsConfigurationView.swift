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
            if let url = viewModel.p8FileURL {
              Text(url.lastPathComponent)
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
