//
//  MainWindBarView.swift
//  WindBar
//
//  Copyright © 2026 db. All rights reserved.
//  Licensed under the MIT License.
//  Please attribute me if you use my work.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct MainWindBarView: View {

    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Current Weather Section
                CurrentWeatherSection()
                    .environmentObject(manager)
                    .environmentObject(settings)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

                // MARK: - Drone Safety Alert
                DroneAlertSection()
                    .environmentObject(settings)
                    .environmentObject(manager)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

                // MARK: - Location Section
                LocationSection()
                    .environmentObject(manager)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

                // MARK: - Display Settings
                DisplaySection()
                    .environmentObject(manager)
                    .environmentObject(settings)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

                // MARK: - Next Hours
                NextHoursSection()
                    .environmentObject(manager)
                    .environmentObject(settings)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

                // MARK: - External Links
                ExternalLinksSection()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

            }
            .padding(16)
        }
        .frame(width: settings.windowWidth.width)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Current Weather Section

struct CurrentWeatherSection: View {

    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Current Weather")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)

            // Time and coordinates
            VStack(alignment: .leading, spacing: 6) {
                if let updated = manager.lastUpdated {
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text(timeString(updated))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                if let lat = manager.latitude, let lon = manager.longitude {
                    HStack(spacing: 10) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text(String(format: "%.3f, %.3f", lat, lon))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Wind speed - Featured
            if let speed = manager.windSpeedKmh {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "wind")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(String(format: "%.1f", speed))
                                    .font(.system(.largeTitle, design: .rounded))
                                    .fontWeight(.bold)
                                Text(manager.windUnit.displayName)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                if let compass = manager.windDirectionCompass {
                                    Text(compass)
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                            }
                            // Show knots if enabled
                            if settings.showKnotsAlways && manager.windUnit != .knots {
                                Text(String(format: "(%.1f knots)", settings.windSpeedInKnots(speed)))
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            // Gusts
            if let gust = manager.windGustKmh, let compass = manager.windDirectionCompass {
                HStack(spacing: 12) {
                    Image(systemName: "wind.snow")
                        .foregroundColor(.orange)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("Gusts")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            if let deg = manager.windDirectionDeg {
                                Text(windArrow(for: deg))
                                    .font(.title3)
                            }
                            Text(String(format: "%.1f %@ %@", gust, manager.windUnit.displayName, compass))
                                .font(.headline)
                        }
                        // Show knots if enabled
                        if settings.showKnotsAlways && manager.windUnit != .knots {
                            Text(String(format: "(%.1f knots)", settings.windSpeedInKnots(gust)))
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Divider()

            // Additional weather data
            VStack(alignment: .leading, spacing: 10) {
                // Temperature
                if let temp = manager.temperatureC {
                    HStack(spacing: 12) {
                        Image(systemName: "thermometer.medium")
                            .foregroundColor(.red)
                            .frame(width: 28)
                        Text("Temperature")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Text(settings.temperatureString(temp))
                            .fontWeight(.medium)
                    }
                    .font(.body)
                }

                // Pressure
                if let pressure = manager.pressureHPa {
                    HStack(spacing: 12) {
                        Image(systemName: "barometer")
                            .foregroundColor(.purple)
                            .frame(width: 28)
                        Text("Pressure")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Text(settings.pressureString(pressure))
                            .fontWeight(.medium)
                    }
                    .font(.body)
                }

                // UV Index
                if let uv = manager.uvIndex {
                    HStack(spacing: 12) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 28)
                        Text("UV Index")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        Text(String(format: "%.1f", uv))
                            .fontWeight(.medium)
                        Text("—")
                            .foregroundColor(.secondary)
                        Text(uvLevel(uv))
                            .fontWeight(.medium)
                            .foregroundColor(uvColor(uv))
                    }
                    .font(.body)
                }
            }
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func uvLevel(_ index: Double) -> String {
        switch index {
        case 0..<3: return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default: return "Extreme"
        }
    }

    private func uvColor(_ index: Double) -> Color {
        switch index {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default: return .purple
        }
    }

    private func windArrow(for degrees: Double) -> String {
        // Wind direction: arrow points in the direction the wind is FROM
        // Meteorological convention: 0° = North wind (from North)
        let normalized = Int(degrees) % 360

        switch normalized {
        case 337...360, 0..<23:   return "↑"  // N
        case 23..<68:             return "↗"  // NE
        case 68..<113:            return "→"  // E
        case 113..<158:           return "↘"  // SE
        case 158..<203:           return "↓"  // S
        case 203..<248:           return "↙"  // SW
        case 248..<293:           return "←"  // W
        case 293..<338:           return "↖"  // NW
        default:                  return "↑"
        }
    }
}

// MARK: - Drone Alert Section

struct DroneAlertSection: View {

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var manager: WeatherManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                Text("Drone Safety Alert")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
            }

            Toggle(isOn: $settings.enableWindAlerts) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(settings.enableWindAlerts ? .orange : .secondary)
                    Text("Enable wind alerts")
                        .font(.body)
                }
            }
            .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text("Wind limit:")
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .leading)
                    TextField("Limit", value: $settings.customDroneWindLimit, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    Text("km/h")
                        .foregroundColor(.secondary)
                }

                Text("(\(formattedWindLimit()))")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.leading, 100)
            }

            HStack {
                Text("Alert sound:")
                    .foregroundColor(.secondary)
                Spacer()
                Picker("Alert sound", selection: $settings.alertSound) {
                    ForEach(AlertSound.allCases) { sound in
                        Text(sound.rawValue).tag(sound)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }

            // Show custom sound file picker when Custom is selected
            if settings.alertSound == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "music.note")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text("Sound file:")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        if !settings.customSoundPath.isEmpty {
                            Text(customSoundFileName())
                                .font(.callout)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                )
                        } else {
                            Text("None selected")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        Spacer()
                        Button(action: {
                            selectCustomSound()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "folder")
                                Text("Choose...")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func customSoundFileName() -> String {
        let url = URL(fileURLWithPath: settings.customSoundPath)
        return url.lastPathComponent
    }

    private func selectCustomSound() {
        let panel = NSOpenPanel()
        panel.title = "Select Custom Alert Sound"
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            settings.customSoundPath = url.path
        }
    }

    private func formattedWindLimit() -> String {
        let converted: Double
        let unit = manager.windUnit.displayName

        switch manager.windUnit {
        case .kmh:
            converted = settings.customDroneWindLimit
        case .mph:
            converted = settings.customDroneWindLimit * 0.621371
        case .ms:
            converted = settings.customDroneWindLimit / 3.6
        case .knots:
            converted = settings.customDroneWindLimit * 0.539957
        }

        return String(format: "%.0f %@", converted, unit)
    }
}

// MARK: - Location Section

struct LocationSection: View {

    @EnvironmentObject var manager: WeatherManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("Location")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
            }

            // Mode picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Mode")
                    .foregroundColor(.secondary)
                    .font(.callout)
                Picker("Mode", selection: $manager.locationMode) {
                    Text("City").tag(LocationMode.cityName)
                    Text("Coords").tag(LocationMode.coordinates)
                    Text("World").tag(LocationMode.countryCity)
                }
                .pickerStyle(.segmented)
            }

            // Different inputs based on mode
            VStack(alignment: .leading, spacing: 12) {
                switch manager.locationMode {
                case .cityName:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("City name")
                            .foregroundColor(.secondary)
                            .font(.callout)
                        TextField("Enter city name", text: $manager.cityName)
                            .textFieldStyle(.roundedBorder)
                    }

                case .coordinates:
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Text("Lat")
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)
                            TextField("Latitude", value: $manager.latitude, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack(spacing: 10) {
                            Text("Lon")
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)
                            TextField("Longitude", value: $manager.longitude, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                case .countryCity:
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Country")
                            .foregroundColor(.secondary)
                            .font(.callout)
                        Picker("Country", selection: $manager.selectedCountry) {
                            ForEach(Array(manager.cityList.keys.sorted()), id: \.self) { country in
                                Text("\(manager.flagEmoji(for: country)) \(country)")
                                    .tag(country)
                            }
                        }

                        Text("City")
                            .foregroundColor(.secondary)
                            .font(.callout)
                        Picker("City", selection: $manager.selectedCity) {
                            ForEach(manager.cityList[manager.selectedCountry] ?? [], id: \.self) { city in
                                Text(city).tag(city)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Display Section

struct DisplaySection: View {

    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var settings: AppSettings
    @State private var showWindLimits = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Display")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
            }

            // Unit picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Wind units")
                    .foregroundColor(.secondary)
                    .font(.callout)
                Picker("Units", selection: $manager.windUnit) {
                    ForEach(WindUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Temperature unit
            VStack(alignment: .leading, spacing: 10) {
                Text("Temperature")
                    .foregroundColor(.secondary)
                    .font(.callout)
                Picker("Temperature", selection: $settings.temperatureUnit) {
                    ForEach(TemperatureUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Pressure unit
            VStack(alignment: .leading, spacing: 10) {
                Text("Pressure")
                    .foregroundColor(.secondary)
                    .font(.callout)
                Picker("Pressure", selection: $settings.pressureUnit) {
                    ForEach(PressureUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider()

            // Window width
            VStack(alignment: .leading, spacing: 10) {
                Text("Window width")
                    .foregroundColor(.secondary)
                    .font(.callout)
                Picker("Window width", selection: $settings.windowWidth) {
                    ForEach(WindowWidth.allCases) { width in
                        Text(width.displayName).tag(width)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider()

            // Toggles
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $settings.showKnotsAlways) {
                    HStack(spacing: 8) {
                        Image(systemName: "wind")
                            .foregroundColor(.blue)
                        Text("Always show wind in knots")
                    }
                }
                .toggleStyle(.switch)

                Toggle(isOn: $manager.useDummyData) {
                    HStack(spacing: 8) {
                        Image(systemName: "testtube.2")
                            .foregroundColor(.purple)
                        Text("Use dummy data")
                        Text("(dev use only)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }

            Divider()

            // Auto-refresh
            VStack(alignment: .leading, spacing: 10) {
                Text("Auto-refresh")
                    .foregroundColor(.secondary)
                    .font(.callout)
                HStack(spacing: 10) {
                    TextField("Minutes", value: $manager.refreshIntervalMinutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                    Text("minutes")
                        .foregroundColor(.secondary)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    manager.refresh()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh now")
                    }
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    showWindLimits = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                        Text("Wind limits")
                    }
                }
                .buttonStyle(.bordered)
            }
            .sheet(isPresented: $showWindLimits) {
                DroneWindLimitsView()
                    .environmentObject(manager)
            }
        }
    }
}

// MARK: - Next Hours Section

struct NextHoursSection: View {

    @EnvironmentObject var manager: WeatherManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.indigo)
                    .font(.title3)
                Text("Hourly Forecast")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
            }

            if manager.hourlyForecast.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("No forecast data available")
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(manager.hourlyForecast) { entry in
                        HourlyRow(entry: entry)
                    }
                }
            }
        }
    }
}

struct HourlyRow: View {

    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var settings: AppSettings
    let entry: HourlyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                // Time
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.indigo)
                        .font(.caption)
                        .frame(width: 16)
                    Text(entry.label)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .frame(width: 55, alignment: .leading)
                }

                // Wind speed
                if let speed = entry.windSpeed {
                    HStack(spacing: 6) {
                        Image(systemName: "wind")
                            .foregroundColor(.blue)
                            .font(.caption)
                            .frame(width: 16)
                        Text(String(format: "%.1f", speed))
                            .fontWeight(.semibold)
                        Text(manager.windUnit.displayName)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 100, alignment: .leading)
                }

                // Gust
                if let gust = entry.windGust, let compass = entry.windDirectionCompass {
                    HStack(spacing: 6) {
                        Image(systemName: "wind.snow")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(String(format: "%.1f %@ %@", gust, manager.windUnit.displayName, compass))
                            .font(.callout)
                    }
                }

                Spacer()

                // Pressure
                if let pressure = entry.pressureHPa {
                    Text(String(format: "%.0f hPa", pressure))
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .font(.body)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
            )

            // Show knots if enabled
            if settings.showKnotsAlways && manager.windUnit != .knots {
                HStack(spacing: 12) {
                    Spacer()
                        .frame(width: 16)
                    Spacer()
                        .frame(width: 55)
                    Spacer()
                        .frame(width: 16)

                    if let speed = entry.windSpeed {
                        Text(String(format: "(%.1f knots", settings.convertToKnots(speed, from: manager.windUnit)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                    }

                    if let gust = entry.windGust {
                        Text(String(format: "· %.1f knots)", settings.convertToKnots(gust, from: manager.windUnit)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 10)
            }
        }
    }
}

// MARK: - External Links Section

struct ExternalLinksSection: View {

    @EnvironmentObject var manager: WeatherManager
    @State private var showProPilots = false
    @State private var showICAOList = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(.teal)
                    .font(.title3)
                Text("External Links")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
            }

            Text("External weather sources")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button(action: {
                    openWeatherChannel()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                        Text("Weather Channel")
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.bordered)

                Button(action: {
                    showICAOList = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                        Text("ICAO List")
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.bordered)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Australian Airspace - Official Sources")
                    .font(.headline)

                Text("Official external sources")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    LinkButton(title: "Open AIP", icon: "doc.text", url: "https://www.airservicesaustralia.com/aip")
                    LinkButton(title: "Open NAIPS$ (NOTAMs/Briefing) — paid service", icon: "doc.text", url: "https://www.airservicesaustralia.com/naips/Account/Logon")
                    LinkButton(title: "Open CASA RPAS Gui...", icon: "doc.text", url: "https://www.casa.gov.au/drones")
                    LinkButton(title: "BOM Weather", icon: "cloud.sun", url: "http://www.bom.gov.au")
                    LinkButton(title: "Weatherzone Radar", icon: "waveform.path.ecg", url: "https://www.weatherzone.com.au/radar")
                }

                Text("Airspace and NOTAMs change frequently. Always check official sources before flight.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Aviation Resources")
                    .font(.headline)

                HStack(spacing: 12) {
                    LinkButton(title: "ICAO Lookup", icon: "magnifyingglass", url: "https://ourairports.com/")
                    LinkButton(title: "FlightAware", icon: "airplane", url: "https://www.flightaware.com")
                }

                Button(action: {
                    showProPilots = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                        Text("Pro pilots I recommend")
                    }
                }
                .buttonStyle(.link)
                .padding(.top, 4)
            }
            .sheet(isPresented: $showProPilots) {
                ProPilotsView()
            }
            .sheet(isPresented: $showICAOList) {
                AustralianICAOView()
            }

            Divider()

            // Attribution
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("About")
                        .font(.headline)
                }

                Text("This app is free and distributable. The source is available under the MIT license.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: {
                    if let url = URL(string: "https://github.com/FPV-dB/windbar-recovery") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.caption)
                        Text("View on GitHub")
                    }
                    .font(.caption)
                }
                .buttonStyle(.link)

                Text("MIT License © 2026 db")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func openWeatherChannel() {
        var urlString = "https://weather.com/weather/today/l/"

        if let lat = manager.latitude, let lon = manager.longitude {
            // Use coordinates format: weather.com/weather/today/l/LAT,LON
            urlString += String(format: "%.4f,%.4f", lat, lon)
        } else {
            // Fallback to city name if coordinates not available
            let city = manager.cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Adelaide"
            urlString += city
        }

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

struct LinkButton: View {
    let title: String
    let icon: String
    let url: String?
    var customAction: (() -> Void)?

    init(title: String, icon: String, url: String?) {
        self.title = title
        self.icon = icon
        self.url = url
        self.customAction = nil
    }

    init(title: String, icon: String, customAction: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.url = nil
        self.customAction = customAction
    }

    var body: some View {
        Button(action: {
            if let action = customAction {
                action()
            } else if let urlString = url, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .lineLimit(1)
            }
            .font(.callout)
        }
        .buttonStyle(.link)
    }
}
