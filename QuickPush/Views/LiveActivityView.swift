//
//  LiveActivityView.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

struct LiveActivityView: View {
  var isActive: Bool = true
  @Environment(WindowManager.self) var windowManager
  @State private var viewModel = LiveActivityViewModel()

  var body: some View {
    VStack(spacing: 16) {
      // Title bar
      HStack {
        Text("Live Activity")
          .font(.headline)
        Spacer()
        if viewModel.lastResponse != nil {
          Button {
            viewModel.showResponseSheet = true
          } label: {
            HStack(spacing: 4) {
              Circle()
                .fill(viewModel.lastResponse?.isSuccess == true ? Color.green : Color.red)
                .frame(width: 6, height: 6)
              Text("Response")
            }
          }
          .controlSize(.small)
        }
        Button("JSON") {
          viewModel.showJSONSheet = true
        }
        .controlSize(.small)
        Button {
          viewModel.send()
        } label: {
          HStack(spacing: 4) {
            Text("Send")
            HStack(spacing: 1) {
              Image(systemName: "command")
              Image(systemName: "return")
            }
            .font(.caption2)
            .opacity(0.7)
          }
        }
        .applying { view in
          if isActive {
            view.keyboardShortcut(.return, modifiers: .command)
          } else {
            view
          }
        }
        .applying { view in
          if #available(macOS 26.0, *) {
            view.buttonStyle(.glassProminent)
          } else {
            view.buttonStyle(.borderedProminent)
          }
        }
        .disabled(!viewModel.canSend)
      }

      ScrollView(.vertical, showsIndicators: false) {
        VStack(alignment: .leading, spacing: 16) {
          // Event Type Picker
          HStack {
            Text("Event:")
            Picker("", selection: $viewModel.eventType) {
              Text("Start").tag(LiveActivityEvent.start)
              Text("Update").tag(LiveActivityEvent.update)
              Text("End").tag(LiveActivityEvent.end)
            }
            .pickerStyle(.segmented)
          }

          // Token Field
          VStack(alignment: .leading, spacing: 8) {
            Text("\(viewModel.tokenLabel):")
              .font(.subheadline)
            HStack {
              TextField("Hex device token", text: $viewModel.deviceToken)
                .textFieldStyle(.roundedBorder)
              Button(action: { viewModel.pasteToken() }) {
                Image(systemName: "doc.on.clipboard")
                  .foregroundColor(.secondary)
              }
              .buttonStyle(.plain)
              .help("Paste hex token from clipboard")
            }
          }

          Divider()

          // APNs Configuration
          APNsConfigurationView(config: viewModel.config)

          HStack {
            Text("Attributes Type:")
              .frame(width: 95, alignment: .leading)
            TextField("e.g. MyWidget.LiveActivityAttributes", text: $viewModel.attributesType)
              .textFieldStyle(.roundedBorder)
            HelpButton(helpText: "Must match the fully module-qualified Swift type name of your ActivityAttributes struct. Run this in your iOS app to get the exact value:\n\nprint(String(reflecting: LiveActivityAttributes.self))\n\nCommon formats:\n• MyWidgetExtension.LiveActivityAttributes\n• LiveActivityAttributes\n\nA mismatch causes iOS to silently drop the push even if APNs returns 200.")
          }

          Divider()

          // Content State
          LiveActivityContentStateSection(viewModel: viewModel)

          // Attributes (Start only)
          if viewModel.eventType == .start {
            Divider()
            LiveActivityAttributesSection(viewModel: viewModel)
          }

          // Alert (Start only)
          if viewModel.eventType == .start {
            Divider()
            LiveActivityAlertSection(viewModel: viewModel)
          }
        }
      }
    }
    .padding(.horizontal)
    .padding(.top)
    .overlay(
      ToastView(message: viewModel.toastMessage, type: viewModel.toastType, isPresented: $viewModel.showToast)
        .animation(.easeInOut, value: viewModel.showToast)
    )
    .adaptivePresentation(isPresented: $viewModel.showJSONSheet, isPinned: windowManager.isPinned) {
      JSONImportExportView(viewModel: viewModel)
    }
    .adaptivePresentation(isPresented: $viewModel.showResponseSheet, isPinned: windowManager.isPinned) {
      APNsResponseDetailView(response: viewModel.lastResponse)
    }
  }
}
