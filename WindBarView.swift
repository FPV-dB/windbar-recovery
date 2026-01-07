//
//  WindBarView.swift
//  WindBar
//
//  Copyright © 2026 db. All rights reserved.
//  Licensed under the MIT License.
//  Please attribute me if you use my work.
//

import SwiftUI

struct WindBarView: View {

    @EnvironmentObject var manager: WeatherManager

    // NEW: AppDelegate gives us this callback so the view can close the popover
    var onClose: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // --- HEADER ROW WITH TITLE + CLOSE BUTTON ---
            HStack {
                Text("WindBar")
                    .font(.title2)
                Spacer()
                Button(action: { onClose() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }

            // --- WIND DISPLAY ---
            if manager.isLoading {
                Text("Loading…")
            } else if let speed = manager.windSpeedKmh {
                Text("Wind: \(speed, specifier: "%.1f") km/h")
            } else {
                Text("No data")
            }

            // --- CITY INPUT ---
            TextField("City", text: $manager.cityName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // --- UNIT PICKER (if you have the WindUnit enum) ---
            Picker("Units", selection: $manager.windUnit) {
                ForEach(WindUnit.allCases) { unit in
                    Text(unit.displayName)
                        .tag(unit)
                }
            }
            .pickerStyle(.segmented)

            // --- DUMMY DATA TOGGLE ---
            Toggle("Use Dummy Data", isOn: $manager.useDummyData)

            // --- REFRESH BUTTON ---
            Button("Refresh") {
                manager.refresh()
            }
            .padding(.top, 8)

        }
        .padding()
        .frame(width: 260)
    }
}
