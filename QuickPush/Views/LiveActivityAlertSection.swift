//
//  LiveActivityAlertSection.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

struct LiveActivityAlertSection: View {
  @Bindable var viewModel: LiveActivityViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Toggle("Include Alert", isOn: $viewModel.includeAlert)

      if viewModel.includeAlert {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Alert Title:")
            TextField("Alert title", text: $viewModel.alertTitle)
              .textFieldStyle(.roundedBorder)
          }

          HStack {
            Text("Alert Body:")
            TextField("Alert body", text: $viewModel.alertBody)
              .textFieldStyle(.roundedBorder)
          }

          HStack {
            Text("Sound:")
            TextField("default", text: $viewModel.alertSound)
              .textFieldStyle(.roundedBorder)
          }
        }
        .padding(.leading, 16)
      }
    }
  }
}
