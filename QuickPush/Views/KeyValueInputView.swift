//
//  KeyValueInputView.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import SwiftUI

struct KeyValueInputView: View {
  @Binding var data: [String: String]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text("Custom Data (JSON)")
        .font(.subheadline)
      
      ForEach(Array(data.keys), id: \.self) { key in
        HStack {
          TextField("Key", text: Binding(
            get: { key },
            set: { newKey in
              if let value = data[key] {
                data.removeValue(forKey: key)
                data[newKey] = value
              }
            }
          ))
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .frame(width: 100)
          
          Text(":")
          
          TextField("Value", text: Binding(
            get: { data[key] ?? "" },
            set: { newValue in data[key] = newValue }
          ))
          .textFieldStyle(RoundedBorderTextFieldStyle())
          
          Button(action: { data.removeValue(forKey: key) }) {
            Image(systemName: "minus.circle.fill")
              .foregroundColor(.red)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      
      Button(action: { data[""] = "" }) {
        HStack {
          Image(systemName: "plus.circle.fill")
          Text("Add Key-Value")
        }
      }
      .buttonStyle(.borderless)
      .padding(.top, 5)
    }
  }
}
