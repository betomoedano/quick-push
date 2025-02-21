//
//  KeyValueInputView.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import SwiftUI

struct KeyValueInputView: View {
    @Binding var data: [String: String]
    @State private var editingKeys: [String: String] = [:] // Temporary key storage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Custom Data:")
                    .font(.subheadline)
                HelpButton(helpText: "Add custom JSON data to be sent with the notification. Up to 4KB total payload size.")
            }
            
            if data.isEmpty {
                Text("No custom data")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 4)
            }
            
            ForEach(Array(data.keys), id: \.self) { key in
                HStack(spacing: 8) {
                    // Key Input
                    TextField("Key", text: Binding(
                        get: { editingKeys[key] ?? key },
                        set: { newKey in
                            let sanitizedKey = sanitizeKey(newKey)
                            editingKeys[key] = sanitizedKey
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 120)
                    .onSubmit {
                        finalizeKeyEdit(oldKey: key)
                    }

                    Text(":")
                        .foregroundColor(.secondary)
                    
                    // Value Input
                    TextField("Value", text: Binding(
                        get: { data[key] ?? "" },
                        set: { newValue in data[key] = newValue }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    // Remove Button
                    Button(action: { removeKey(key) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Remove this key-value pair")
                }
            }
            
            // Add Button
            Button(action: { addNewKeyValue() }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Key-Value Pair")
                }
            }
            .buttonStyle(.borderless)
            .disabled(data.count >= 10) // Prevent too many items
            .help(data.count >= 10 ? "Maximum number of custom data pairs reached" : "Add a new key-value pair")
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Functions
    
    /// Sanitizes a key: lowercase, replaces spaces with "-", removes invalid characters
    private func sanitizeKey(_ key: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return key
            .lowercased()
            .replacingOccurrences(of: " ", with: "-") // Replace spaces with "-"
            .components(separatedBy: allowedCharacters.inverted) // Remove special characters
            .joined()
    }

    /// Finalizes key edit: prevents empty or duplicate keys
    private func finalizeKeyEdit(oldKey: String) {
        if let newKey = editingKeys[oldKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !newKey.isEmpty,
           newKey != oldKey,
           !data.keys.contains(newKey) { // Prevent duplicate keys
            if let value = data.removeValue(forKey: oldKey) {
                data[newKey] = value
            }
        }
        editingKeys[oldKey] = nil // Clear temp key storage
    }

    /// Adds a new key-value pair with a default key
    private func addNewKeyValue() {
        guard data.count < 10 else { return } // Safety check
        
        let baseKey = "key"
        var newKey = baseKey
        var counter = 1

        while data.keys.contains(newKey) {
            newKey = "\(baseKey)\(counter)"
            counter += 1
        }

        data[newKey] = ""
        editingKeys[newKey] = newKey
    }

    /// Removes a key-value pair
    private func removeKey(_ key: String) {
        data.removeValue(forKey: key)
        editingKeys.removeValue(forKey: key)
    }
}
