//
//  JSONImportExportView.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

struct JSONImportExportView: View {
  @Bindable var viewModel: LiveActivityViewModel
  @State private var jsonText: String = ""
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text("JSON Payload")
          .font(.headline)
        Spacer()
        Button("Close") { dismiss() }
          .keyboardShortcut(.cancelAction)
      }

      TextEditor(text: $jsonText)
        .font(.system(.body, design: .monospaced))
        .frame(minHeight: 250)
        .border(Color.secondary.opacity(0.3))

      HStack {
        Button("Export") {
          jsonText = viewModel.exportJSON()
        }
        .help("Generate JSON from current form values")

        Button("Copy") {
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(jsonText, forType: .string)
        }
        .help("Copy JSON to clipboard")
        .disabled(jsonText.isEmpty)

        Spacer()

        Button("Paste") {
          if let clipboardString = NSPasteboard.general.string(forType: .string) {
            jsonText = clipboardString
          }
        }
        .help("Paste JSON from clipboard")

        Button("Import") {
          if viewModel.importJSON(jsonText) {
            dismiss()
          }
        }
        .help("Apply JSON to form fields")
        .disabled(jsonText.isEmpty)
      }
    }
    .padding()
    .frame(minWidth: 400, minHeight: 350)
    .onAppear {
      jsonText = viewModel.exportJSON()
    }
  }
}
