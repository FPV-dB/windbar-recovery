//
//  ProPilotsView.swift
//  WindBar
//
//  Copyright © 2026 db. All rights reserved.
//  Licensed under the MIT License.
//  Please attribute me if you use my work.
//

import SwiftUI
import AppKit

struct YouTubePilot {
    let name: String
    let url: String
    let description: String?
}

struct ProPilotsView: View {

    @Environment(\.dismiss) var dismiss

    let pilots = [
        YouTubePilot(name: "BotGrinder", url: "https://www.youtube.com/@BOTGRINDER", description: nil),
        YouTubePilot(name: "Spider Sugar FPV", url: "https://www.youtube.com/@spidersugar_fpv", description: nil),
        YouTubePilot(name: "Joshua Bardwell", url: "https://www.youtube.com/channel/UCX3eufnI7A2I7IkKHZn8KSQ", description: "DIY Expert"),
        YouTubePilot(name: "Mr Steele", url: "https://www.youtube.com/MrSteelefpv/videos", description: nil),
        YouTubePilot(name: "Koala FPV", url: "https://www.youtube.com/@koalafpv", description: nil),
        YouTubePilot(name: "Ken Heron", url: "https://www.youtube.com/@Kenheron", description: "Funny expert pilot — Part 107"),
        YouTubePilot(name: "Grim Ripper", url: "https://www.youtube.com/@grimripperrr", description: nil)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Header
            HStack {
                Text("Pro pilots I recommend")
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

            // FlowState Documentary - Featured
            Button(action: {
                if let url = URL(string: "https://youtu.be/UoMWFrqOmQo") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "film.fill")
                        .foregroundColor(.red)
                    Text("•")
                        .foregroundColor(.red)
                    Text("FlowState - FPV documentary (must see)")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .font(.body)
            }
            .buttonStyle(.link)
            .padding(.vertical, 4)

            Divider()

            // Subtitle
            Text("YouTube channels worth following")
                .font(.headline)

            // Pilot list
            VStack(alignment: .leading, spacing: 10) {
                ForEach(pilots, id: \.name) { pilot in
                    Button(action: {
                        if let url = URL(string: pilot.url) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(.red)
                            Text("•")
                            Text(pilot.name)
                                .fontWeight(.medium)
                            if let desc = pilot.description {
                                Text("—")
                                    .foregroundColor(.secondary)
                                Text(desc)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.body)
                    }
                    .buttonStyle(.link)
                }
            }
            .padding(.vertical, 8)

            Divider()

            // Tip
            Text("Tip: Click any channel to open in your browser.")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(24)
        .frame(width: 500, height: 450)
    }
}
