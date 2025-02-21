//
//  ContentView.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import SwiftUI

struct ContentView: View {
  @State private var tokens: [String] = [""]
  @State private var title: String = ""
  @State private var notificationBody: String = ""
  @State private var sound: String = "default"
  @State private var priority: PushNotification.Priority = .default
  @State private var ttl: String = ""
  @State private var expiration: String = ""
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Expo Push Notification")
        .font(.headline)
      
      // Tokens Section
      Text("Expo Push Tokens:")
        .font(.subheadline)
      
      ForEach(tokens.indices, id: \.self) { index in
        HStack {
          TextField("Enter push token", text: $tokens[index])
            .textFieldStyle(RoundedBorderTextFieldStyle())
          
          if tokens.count > 1 {
            Button(action: { tokens.remove(at: index) }) {
              Image(systemName: "minus.circle.fill")
                .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
      }
      
      Button(action: { tokens.append("") }) {
        HStack {
          Image(systemName: "plus.circle.fill")
          Text("Add Token")
        }
      }
      .buttonStyle(.borderless)
      .padding(.top, 5)
      
      Divider()
      
      // Notification Fields
      VStack(alignment: .leading, spacing: 8) {
        InputField(label: "Title", text: $title, helpText: "Title of the notification")
        InputField(label: "Body", text: $notificationBody, helpText: "Message content displayed in the notification")
        InputField(label: "Sound (iOS)", text: $sound, helpText: "Specify 'default' or custom sound name (iOS only)")
        
        // Priority Picker
        HStack {
          Text("Priority:")
          Picker("", selection: $priority) {
            Text("Default").tag(PushNotification.Priority.default)
            Text("Normal").tag(PushNotification.Priority.normal)
            Text("High").tag(PushNotification.Priority.high)
          }
          .pickerStyle(SegmentedPickerStyle())
          
          HelpButton(helpText: "Affects delivery timing. 'High' wakes sleeping devices.")
        }
        
        // TTL Input
        InputField(label: "TTL", text: $ttl, helpText: "Time-to-live in seconds (leave blank for default)")
        
        // Expiration Input
        InputField(label: "Expiration", text: $expiration, helpText: "Unix timestamp for expiration (optional)")
      }
      
      // Send Button
      Button("Send Push") {
        sendPushNotification()
      }
      .buttonStyle(.borderedProminent)
      .padding(.top, 10)
    }
    .padding()
    .frame(width: 350)
  }
  
  private func sendPushNotification() {
    print("Sending push to: \(tokens.filter { !$0.isEmpty })")
    // API call logic goes here
  }
}

// MARK: - Reusable InputField with Tooltip
struct InputField: View {
  let label: String
  @Binding var text: String
  let helpText: String
  
  var body: some View {
    HStack {
      Text("\(label):")
      TextField(label, text: $text)
        .textFieldStyle(RoundedBorderTextFieldStyle())
      HelpButton(helpText: helpText)
    }
  }
}

// MARK: - Help Button with Popover
struct HelpButton: View {
  let helpText: String
  @State private var showHelp = false
  
  var body: some View {
    Button(action: { showHelp.toggle() }) {
      Image(systemName: "questionmark.circle")
        .foregroundColor(.blue)
    }
    .popover(isPresented: $showHelp) {
      Text(helpText)
        .padding()
        .frame(width: 250)
    }
    .buttonStyle(PlainButtonStyle())
  }
}
#Preview {
  ContentView()
}
