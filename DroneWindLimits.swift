//
//  DroneWindLimits.swift
//  WindBar
//

import SwiftUI

struct DroneModel {
    let name: String
    let maxWindKmh: Double
}

struct DroneWindLimitsView: View {

    @EnvironmentObject var manager: WeatherManager
    @Environment(\.dismiss) var dismiss

    let droneModels = [
        DroneModel(name: "DJI Avata 2", maxWindKmh: 25), // 20-30 km/h average
        DroneModel(name: "DJI Neo 1", maxWindKmh: 15),
        DroneModel(name: "DJI Neo 2", maxWindKmh: 20),
        DroneModel(name: "DJI Mini 3", maxWindKmh: 35),
        DroneModel(name: "DJI Mini 4 Pro", maxWindKmh: 35),
        DroneModel(name: "DJI Air 3S", maxWindKmh: 40),
        DroneModel(name: "DJI Matrice Series 4", maxWindKmh: 40),
        DroneModel(name: "DJI Agras T50", maxWindKmh: 20)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Header
            HStack {
                Text("Recommended wind limits")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Subtitle
            Text("Recommended maximum wind speeds")
                .font(.headline)

            // Drone list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(droneModels, id: \.name) { drone in
                    HStack(spacing: 4) {
                        Text("•")
                        Text(drone.name)
                            .fontWeight(.medium)
                        Text("—")
                            .foregroundColor(.secondary)
                        Text(formatWindSpeed(drone.maxWindKmh))
                    }
                    .font(.body)
                }
            }
            .padding(.vertical, 8)

            Divider()

            // Tip
            Text("Tip: Adjust units in Display to see values change.")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(24)
        .frame(width: 500, height: 450)
    }

    private func formatWindSpeed(_ kmh: Double) -> String {
        let converted: Double
        let unit = manager.windUnit.displayName

        switch manager.windUnit {
        case .kmh:
            converted = kmh
        case .mph:
            converted = kmh * 0.621371
        case .ms:
            converted = kmh / 3.6
        case .knots:
            converted = kmh * 0.539957
        }

        return String(format: "%.0f %@", converted, unit)
    }
}
