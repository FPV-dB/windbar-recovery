//
//  AustralianICAOView.swift
//  WindBar
//

import SwiftUI

struct ICAOAirport: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let isMajor: Bool
}

struct AustralianICAOView: View {

    @Environment(\.dismiss) var dismiss

    let airports = [
        // Major Airports
        ICAOAirport(code: "YSSY", name: "Sydney Kingsford Smith", isMajor: true),
        ICAOAirport(code: "YMML", name: "Melbourne Tullamarine", isMajor: true),
        ICAOAirport(code: "YBBN", name: "Brisbane", isMajor: true),
        ICAOAirport(code: "YPAD", name: "Adelaide", isMajor: true),
        ICAOAirport(code: "YPPH", name: "Perth", isMajor: true),
        ICAOAirport(code: "YSCB", name: "Canberra", isMajor: true),
        ICAOAirport(code: "YBCG", name: "Gold Coast", isMajor: true),
        ICAOAirport(code: "YPPD", name: "Darwin", isMajor: true),
        ICAOAirport(code: "YBAS", name: "Alice Springs", isMajor: true),
        ICAOAirport(code: "YBHM", name: "Hamilton Island", isMajor: true),
        ICAOAirport(code: "YBTL", name: "Townsville", isMajor: true),

        // Regional Airports
        ICAOAirport(code: "YSSY", name: "Bankstown (Greater Sydney)", isMajor: false),
        ICAOAirport(code: "YBCS", name: "Cairns", isMajor: false),
        ICAOAirport(code: "YBMC", name: "Sunshine Coast", isMajor: false),
        ICAOAirport(code: "YBAS", name: "Alice Springs", isMajor: false),
        ICAOAirport(code: "YPPD", name: "Darwin", isMajor: false),
        ICAOAirport(code: "YPWR", name: "Woomera", isMajor: false),
        ICAOAirport(code: "YPLC", name: "Port Lincoln", isMajor: false),
        ICAOAirport(code: "YPPF", name: "Parafield (Adelaide)", isMajor: false),
        ICAOAirport(code: "YBUD", name: "Bundaberg", isMajor: false),
        ICAOAirport(code: "YBMA", name: "Mount Isa", isMajor: false),
        ICAOAirport(code: "YBTR", name: "Blackwater", isMajor: false),
        ICAOAirport(code: "YBLT", name: "Ballarat", isMajor: false)
    ]

    @State private var selectedType: AirportType = .major

    enum AirportType: String, CaseIterable {
        case major = "Major Airports"
        case regional = "Regional Airports"
    }

    var filteredAirports: [ICAOAirport] {
        airports.filter { airport in
            selectedType == .major ? airport.isMajor : !airport.isMajor
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Header
            HStack {
                Text("Australian ICAO Codes")
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

            // Airport Type Picker
            HStack {
                Text("Airport Type")
                Spacer()
                Picker("Airport Type", selection: $selectedType) {
                    ForEach(AirportType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }

            // Airport list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(filteredAirports) { airport in
                        HStack(spacing: 12) {
                            Text(airport.code)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                                .frame(width: 60, alignment: .leading)
                            Text(airport.name)
                        }
                        .font(.body)
                    }
                }
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 500, height: 450)
    }
}
