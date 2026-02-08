//
//  LiveActivityContentStateSection.swift
//  QuickPush
//
//  Created by beto on 2/8/26.
//

import SwiftUI

struct LiveActivityContentStateSection: View {
  @Bindable var viewModel: LiveActivityViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Content State")
        .font(.subheadline)
        .fontWeight(.medium)

      HStack {
        Text("Title:")
        TextField("Activity title", text: $viewModel.contentTitle)
          .textFieldStyle(.roundedBorder)
      }

      HStack {
        Text("Subtitle:")
        TextField("Activity subtitle", text: $viewModel.contentSubtitle)
          .textFieldStyle(.roundedBorder)
      }

      // Progress
      Toggle("Include Progress", isOn: $viewModel.includeProgress)
      if viewModel.includeProgress {
        HStack {
          Text("Progress:")
          Slider(value: $viewModel.progress, in: 0...1, step: 0.01)
          Text("\(Int(viewModel.progress * 100))%")
            .frame(width: 40, alignment: .trailing)
            .font(.system(.body, design: .monospaced))
        }
        .padding(.leading, 16)
      }

      // Timer End Date
      Toggle("Include Timer End Date", isOn: $viewModel.includeTimerEnd)
      if viewModel.includeTimerEnd {
        HStack {
          Text("Timer End:")
          DatePicker("", selection: $viewModel.timerEndDate)
            .labelsHidden()
        }
        .padding(.leading, 16)
      }

      // Elapsed Timer
      Toggle("Include Elapsed Timer", isOn: $viewModel.includeElapsedTimer)
      if viewModel.includeElapsedTimer {
        HStack {
          Text("Start Date:")
          DatePicker("", selection: $viewModel.elapsedTimerStartDate)
            .labelsHidden()
        }
        .padding(.leading, 16)
      }

      HStack {
        Text("Image Name:")
        TextField("Optional image name", text: $viewModel.imageName)
          .textFieldStyle(.roundedBorder)
      }

      HStack {
        Text("DI Image:")
        TextField("Dynamic Island image", text: $viewModel.dynamicIslandImageName)
          .textFieldStyle(.roundedBorder)
      }
    }
  }
}
