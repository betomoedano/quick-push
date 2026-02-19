//
//  FCMView.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

struct FCMView: View {
  var isActive: Bool = true
  @Environment(WindowManager.self) var windowManager
  @State private var viewModel = FCMViewModel()

  var body: some View {
    VStack(spacing: 16) {
      // Title bar
      HStack {
        Text("FCM")
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
        Button("cURL") {
          viewModel.curlCommand = viewModel.generateCurlCommand()
          viewModel.showCurlSheet = true
        }
        .controlSize(.small)
        .disabled(!viewModel.canSend)
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
          // Token Section
          VStack(alignment: .leading, spacing: 8) {
            Text("FCM Registration Token:")
              .font(.subheadline)

            // Saved tokens
            ForEach(viewModel.savedTokens) { saved in
              SavedTokenRowView(
                savedToken: saved,
                onToggle: {
                  if let index = viewModel.savedTokens.firstIndex(where: { $0.id == saved.id }) {
                    viewModel.savedTokens[index].isEnabled.toggle()
                    SavedTokenStore.fcm.saveTokens(viewModel.savedTokens)
                  }
                },
                onCopy: {
                  NSPasteboard.general.clearContents()
                  NSPasteboard.general.setString(saved.token, forType: .string)
                  viewModel.showToastMessage("Token copied to clipboard", type: .success)
                },
                onRemove: {
                  SavedTokenStore.fcm.removeToken(id: saved.id)
                  viewModel.savedTokens.removeAll { $0.id == saved.id }
                }
              )
            }

            // Unsaved token rows
            ForEach(viewModel.tokens.indices, id: \.self) { index in
              HStack(spacing: 8) {
                TextField("FCM registration token", text: $viewModel.tokens[index])
                  .textFieldStyle(.roundedBorder)

                Button(action: { viewModel.pasteToken(at: index) }) {
                  Image(systemName: "doc.on.clipboard")
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Paste token from clipboard")

                Button(action: {
                  viewModel.tokenToSave = TokenToSave(index: index, token: viewModel.tokens[index])
                }) {
                  Image(systemName: "square.and.arrow.down")
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.tokens[index].trimmingCharacters(in: .whitespaces).isEmpty)
                .help("Save this token for future sessions")

                if viewModel.tokens.count > 1 || !viewModel.savedTokens.isEmpty {
                  Button(action: { viewModel.tokens.remove(at: index) }) {
                    Image(systemName: "minus.circle.fill")
                      .foregroundColor(.red)
                  }
                  .buttonStyle(.plain)
                }
              }
            }

            Button(action: { viewModel.tokens.append("") }) {
              HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Token")
              }
            }
            .buttonStyle(.borderless)
            .padding(.top, 5)
          }

          // FCM Configuration
          FCMConfigurationView(config: viewModel.config)

          Divider()

          // Message Type Picker
          HStack {
            Text("Message Type:")
            Picker("", selection: $viewModel.messageType) {
              Text("Notification").tag(FCMMessageType.notification)
              Text("Data").tag(FCMMessageType.data)
            }
            .pickerStyle(.segmented)
            HelpButton(helpText: "Notification — displays a visible notification on the device.\nData — delivers a data payload to the app without showing a notification UI.")
          }

          // Notification Fields
          if viewModel.messageType == .notification {
            VStack(alignment: .leading, spacing: 8) {
              InputField(label: "Title", text: $viewModel.title, helpText: "Title of the notification")
              InputField(label: "Body", text: $viewModel.body, helpText: "Main message content")
              InputField(label: "Image URL", text: $viewModel.imageUrl, helpText: "URL of an image to display in the notification")

              Text("Android")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top, 4)
              InputField(label: "Channel ID", text: $viewModel.channelId, helpText: "Android notification channel ID. The app must create this channel. Use \"default\" for the default channel.")
              InputField(label: "Sound", text: $viewModel.sound, helpText: "Sound to play. Use \"default\" for the device default sound.")
              InputField(
                label: "Color",
                text: $viewModel.color,
                helpText: "Hex color that tints the notification's small icon in the status bar (e.g. FF5733 — no # prefix). This affects the icon accent color, not the notification background. Visibility depends on Android version and device."
              )
            }
          }

          // Priority
          HStack {
            Text("Priority:")
            Picker("", selection: $viewModel.priority) {
              Text("HIGH").tag("HIGH")
              Text("NORMAL").tag("NORMAL")
            }
            .pickerStyle(.segmented)
            HelpButton(helpText: "HIGH — wakes the device immediately (use for user-visible notifications).\nNORMAL — may be delayed for battery optimization.")
          }

          // Custom Data
          KeyValueInputView(data: $viewModel.customData)
        }
      }
    }
    .padding(.horizontal)
    .padding(.top)
    .overlay(
      ToastView(message: viewModel.toastMessage, type: viewModel.toastType, isPresented: $viewModel.showToast)
        .animation(.easeInOut, value: viewModel.showToast)
    )
    .adaptivePresentation(isPresented: $viewModel.showResponseSheet, isPinned: windowManager.isPinned) {
      FCMResponseDetailView(response: viewModel.lastResponse)
    }
    .adaptivePresentation(isPresented: $viewModel.showCurlSheet, isPinned: windowManager.isPinned) {
      FCMCurlCommandView(curlCommand: viewModel.curlCommand)
    }
    .adaptivePresentation(item: $viewModel.tokenToSave, isPinned: windowManager.isPinned) { item in
      SaveTokenSheet(
        token: item.token,
        onSave: { label in
          let savedToken = SavedToken(label: label, token: item.token)
          SavedTokenStore.fcm.addToken(savedToken)
          viewModel.savedTokens.append(savedToken)
          if item.index < viewModel.tokens.count {
            viewModel.tokens.remove(at: item.index)
          }
          if viewModel.tokens.isEmpty {
            viewModel.tokens.append("")
          }
        },
        warningText: "FCM registration tokens may change when the user reinstalls the app or clears app data."
      )
    }
  }
}
