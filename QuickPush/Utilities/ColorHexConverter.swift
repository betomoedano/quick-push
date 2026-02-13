//
//  ColorHexConverter.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI
import AppKit

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)

    let r, g, b, a: Double
    switch hex.count {
    case 6:
      (r, g, b, a) = (
        Double((int >> 16) & 0xFF) / 255,
        Double((int >> 8) & 0xFF) / 255,
        Double(int & 0xFF) / 255,
        1
      )
    case 8:
      (r, g, b, a) = (
        Double((int >> 24) & 0xFF) / 255,
        Double((int >> 16) & 0xFF) / 255,
        Double((int >> 8) & 0xFF) / 255,
        Double(int & 0xFF) / 255
      )
    default:
      (r, g, b, a) = (0, 0, 0, 1)
    }

    self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
  }

  func toHexString() -> String {
    guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else {
      return "000000"
    }
    let r = Int(round(nsColor.redComponent * 255))
    let g = Int(round(nsColor.greenComponent * 255))
    let b = Int(round(nsColor.blueComponent * 255))
    return String(format: "%02X%02X%02X", r, g, b)
  }

  func toHexStringWithAlpha() -> String {
    guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else {
      return "000000FF"
    }
    let r = Int(round(nsColor.redComponent * 255))
    let g = Int(round(nsColor.greenComponent * 255))
    let b = Int(round(nsColor.blueComponent * 255))
    let a = Int(round(nsColor.alphaComponent * 255))
    return String(format: "%02X%02X%02X%02X", r, g, b, a)
  }
}
