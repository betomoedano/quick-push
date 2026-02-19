//
//  APNsView.swift
//  QuickPush
//
//  Created by beto on 2/19/26.
//

import SwiftUI

struct APNsView: View {
  @Environment(WindowManager.self) var windowManager
  @State private var viewModel = NativePushViewModel()

  var body: some View {
    VStack(spacing: 16) {
      // Title bar
      HStack {
        Text("APNs")
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
        .keyboardShortcut(.return, modifiers: .command)
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
            Text("Device Token:")
              .font(.subheadline)

            // Saved tokens
            ForEach(viewModel.savedTokens) { saved in
              SavedTokenRowView(
                savedToken: saved,
                onToggle: {
                  if let index = viewModel.savedTokens.firstIndex(where: { $0.id == saved.id }) {
                    viewModel.savedTokens[index].isEnabled.toggle()
                    SavedTokenStore.nativePush.saveTokens(viewModel.savedTokens)
                    // Use the enabled token as the active device token
                    if viewModel.savedTokens[index].isEnabled {
                      viewModel.deviceToken = viewModel.savedTokens[index].token
                    }
                  }
                },
                onCopy: {
                  NSPasteboard.general.clearContents()
                  NSPasteboard.general.setString(saved.token, forType: .string)
                  viewModel.showToastMessage("Token copied to clipboard", type: .success)
                },
                onRemove: {
                  SavedTokenStore.nativePush.removeToken(id: saved.id)
                  viewModel.savedTokens.removeAll { $0.id == saved.id }
                }
              )
            }

            // Unsaved token field
            HStack {
              TextField("Hex device token", text: $viewModel.deviceToken)
                .textFieldStyle(.roundedBorder)
              Button(action: { viewModel.pasteToken() }) {
                Image(systemName: "doc.on.clipboard")
                  .foregroundColor(.secondary)
              }
              .buttonStyle(.plain)
              .help("Paste hex token from clipboard")
              Button(action: {
                viewModel.tokenToSave = TokenToSave(index: 0, token: viewModel.deviceToken)
              }) {
                Image(systemName: "square.and.arrow.down")
                  .foregroundColor(.secondary)
              }
              .buttonStyle(.plain)
              .disabled(viewModel.deviceToken.trimmingCharacters(in: .whitespaces).isEmpty)
              .help("Save this token for future sessions")
            }
          }

          // APNs Configuration
          APNsConfigurationView(config: viewModel.config)

          Divider()

          // Push Type Picker
          HStack {
            Text("Push Type:")
            Picker("", selection: $viewModel.pushType) {
              Text("Alert").tag(NativePushType.alert)
              Text("Background").tag(NativePushType.background)
            }
            .pickerStyle(.segmented)
          }
          .onChange(of: viewModel.pushType) { _, newType in
            viewModel.priority = newType == .background ? 5 : 10
          }

          // Alert Fields
          if viewModel.pushType == .alert {
            VStack(alignment: .leading, spacing: 8) {
              InputField(label: "Title", text: $viewModel.title, helpText: "Title of the notification")
              InputField(label: "Subtitle", text: $viewModel.subtitle, helpText: "Secondary line below the title")
              InputField(label: "Body", text: $viewModel.body, helpText: "Main message content")
              InputField(label: "Sound", text: $viewModel.sound, helpText: "Sound name. Use \"default\" for the system sound, or provide a custom sound file name.")
              InputField(label: "Badge", text: $viewModel.badge, helpText: "Number to display on the app icon badge")
              InputField(
                label: "Image URL",
                text: $viewModel.imageUrl,
                helpText: "URL of an image to display in the notification. Requires a Notification Service Extension in the app. Automatically enables Mutable Content. Injected as body._richContent.image in the payload."
              )
            }
          }

          // Advanced
          DisclosureGroup("Advanced") {
            VStack(alignment: .leading, spacing: 8) {
              InputField(label: "Thread ID", text: $viewModel.threadId, helpText: "Groups related notifications in the notification center")
              InputField(label: "Category", text: $viewModel.categoryId, helpText: "Notification category for interactive actions")

              if viewModel.pushType == .alert {
                HStack {
                  Text("Interruption:")
                  Picker("", selection: $viewModel.interruptionLevel) {
                    ForEach(NativeInterruptionLevel.allCases, id: \.self) { level in
                      Text(level.displayName).tag(level)
                    }
                  }
                  .pickerStyle(.menu)
                  HelpButton(helpText: "Controls delivery timing:\n• Active — default, plays sound and lights screen\n• Passive — delivered quietly, no sound or badge\n• Time Sensitive — breaks through Focus modes\n• Critical — bypasses mute and Focus (requires entitlement)")
                }

                Toggle("Mutable Content", isOn: $viewModel.mutableContent)
                  .help("Allows a Notification Service Extension to modify the payload before display")
              }

              Toggle("Content Available", isOn: $viewModel.contentAvailable)
                .help("Wakes the app in the background to process the notification silently")

              HStack {
                Text("Priority:")
                Picker("", selection: $viewModel.priority) {
                  Text("High (10)").tag(10)
                  Text("Normal (5)").tag(5)
                }
                .pickerStyle(.segmented)
                HelpButton(helpText: "Priority 10 = immediate delivery (wakes device). Priority 5 = normal/background delivery. Background push type requires priority 5.")
              }
            }
            .padding(.top, 8)
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
      APNsResponseDetailView(response: viewModel.lastResponse)
    }
    .adaptivePresentation(isPresented: $viewModel.showCurlSheet, isPinned: windowManager.isPinned) {
      APNsCurlCommandView(curlCommand: viewModel.curlCommand)
    }
    .adaptivePresentation(item: $viewModel.tokenToSave, isPinned: windowManager.isPinned) { item in
      SaveTokenSheet(
        token: item.token,
        onSave: { label in
          let savedToken = SavedToken(label: label, token: item.token)
          SavedTokenStore.nativePush.addToken(savedToken)
          viewModel.savedTokens.append(savedToken)
          viewModel.deviceToken = ""
        },
        warningText: "APNs device tokens may change when you reinstall the app or on OS updates."
      )
    }
  }
}
