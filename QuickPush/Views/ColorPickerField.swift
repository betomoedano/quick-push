//
//  ColorPickerField.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

struct ColorPickerField: View {
  let label: String
  @Binding var color: Color

  var body: some View {
    HStack {
      Text("\(label):")
      Spacer()
      Text(color.toHexString())
        .font(.system(.body, design: .monospaced))
        .foregroundColor(.secondary)
      ColorPicker("", selection: $color, supportsOpacity: label.contains("Subtitle"))
        .labelsHidden()
        .frame(width: 30)
    }
  }
}
