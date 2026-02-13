//
//  LiveActivityAttributesSection.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

struct LiveActivityAttributesSection: View {
  @Bindable var viewModel: LiveActivityViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Attributes")
        .font(.subheadline)
        .fontWeight(.medium)

      HStack {
        Text("Name:")
        TextField("Attribute name", text: $viewModel.attributeName)
          .textFieldStyle(.roundedBorder)
      }

      // Color Pickers
      ColorPickerField(label: "Background", color: $viewModel.backgroundColor)
      ColorPickerField(label: "Title Color", color: $viewModel.titleColor)
      ColorPickerField(label: "Subtitle Color", color: $viewModel.subtitleColor)
      ColorPickerField(label: "Progress Tint", color: $viewModel.progressViewTint)
      ColorPickerField(label: "Progress Label", color: $viewModel.progressViewLabelColor)

      HStack {
        Text("Deep Link URL:")
        TextField("e.g. /dashboard", text: $viewModel.deepLinkUrl)
          .textFieldStyle(.roundedBorder)
      }

      // Timer Type
      HStack {
        Text("Timer Type:")
        Picker("", selection: $viewModel.timerType) {
          Text("Digital").tag("digital")
          Text("Circular").tag("circular")
        }
        .pickerStyle(.segmented)
      }

      // Image Position
      HStack {
        Text("Image Position:")
        Picker("", selection: $viewModel.imagePosition) {
          Text("Left").tag("left")
          Text("Right").tag("right")
        }
        .pickerStyle(.segmented)
      }

      // Image Size
      HStack {
        Text("Image Size:")
        TextField("W", value: $viewModel.imageWidth, format: .number)
          .textFieldStyle(.roundedBorder)
          .frame(width: 60)
        Text("x")
        TextField("H", value: $viewModel.imageHeight, format: .number)
          .textFieldStyle(.roundedBorder)
          .frame(width: 60)
      }

      // Padding
      Toggle("Custom Padding", isOn: $viewModel.useCustomPadding)
      if viewModel.useCustomPadding {
        HStack {
          Text("T:")
          TextField("", value: $viewModel.paddingTop, format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 45)
          Text("B:")
          TextField("", value: $viewModel.paddingBottom, format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 45)
          Text("L:")
          TextField("", value: $viewModel.paddingLeft, format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 45)
          Text("R:")
          TextField("", value: $viewModel.paddingRight, format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 45)
        }
        .padding(.leading, 16)
      } else {
        HStack {
          Text("Padding:")
          TextField("", value: $viewModel.uniformPadding, format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 60)
        }
      }
    }
  }
}
