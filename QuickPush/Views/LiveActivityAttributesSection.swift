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
      ColorPickerField(label: "Progress Tint", color: $viewModel.progressTintColor)
      ColorPickerField(label: "Progress Label", color: $viewModel.progressLabelColor)

      HStack {
        Text("Deep Link URL:")
        TextField("e.g. myapp://activity", text: $viewModel.deepLinkURL)
          .textFieldStyle(.roundedBorder)
      }

      // Timer Type
      HStack {
        Text("Timer Type:")
        Picker("", selection: $viewModel.timerType) {
          Text("Digital").tag("digital")
          Text("Analog").tag("analog")
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
          Text("H:")
          TextField("", value: $viewModel.paddingHorizontal, format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 50)
          Text("T:")
          TextField("", value: $viewModel.paddingTop, format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 50)
          Text("B:")
          TextField("", value: $viewModel.paddingBottom, format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 50)
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
