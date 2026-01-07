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

struct MainWindBarView: View {

    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Current Weather Section
                CurrentWeatherSection()
                    .environmentObject(manager)
                    .environmentObject(settings)

                Divider()

                // MARK: - Drone Safety Alert
                DroneAlertSection()
                    .environmentObject(settings)
                    .environmentObject(manager)

                Divider()

                // MARK: - Location Section
                LocationSection()
                    .environmentObject(manager)

                Divider()

                // MARK: - Display Settings
                DisplaySection()
                    .environmentObject(manager)
                    .environmentObject(settings)

                Divider()

                // MARK: - Next Hours
                NextHoursSection()
                    .environmentObject(manager)
                    .environmentObject(settings)

                Divider()

                // MARK: - External Links
                ExternalLinksSection()

            }
            .padding()
        }
        .frame(width: settings.windowWidth.width)
    }
}

// MARK: - Current Weather Section

struct CurrentWeatherSection: View {

    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Time and coordinates
            if let updated = manager.lastUpdated {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(timeString(updated))
                        .font(.system(.body, design: .monospaced))
                }
            }

            if let lat = manager.latitude, let lon = manager.longitude {
                HStack(spacing: 8) {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.3f, %.3f", lat, lon))
                        .font(.system(.body, design: .monospaced))
                }
            }

            // Wind speed
            if let speed = manager.windSpeedKmh {
                HStack(spacing: 8) {
                    Image(systemName: "wind")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", speed))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.semibold)
                    Text(manager.windUnit.displayName)
                        .font(.title3)
                    if let compass = manager.windDirectionCompass {
                        Text(compass)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                // Show knots if enabled
                if settings.showKnotsAlways && manager.windUnit != .knots {
                    HStack(spacing: 8) {
                        Image(systemName: "wind")
                            .foregroundColor(.clear)
                        Text(String(format: "(%.1f knots)", settings.windSpeedInKnots(speed)))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Gusts
            if let gust = manager.windGustKmh, let compass = manager.windDirectionCompass {
                HStack(spacing: 8) {
                    Image(systemName: "wind.snow")
                        .foregroundColor(.secondary)
                    Text("Gusts")
                        .foregroundColor(.secondary)
                    if let deg = manager.windDirectionDeg {
                        Text(windArrow(for: deg))
                    }
                    Text(String(format: "%.1f %@ %@", gust, manager.windUnit.displayName, compass))
                }
                .font(.body)
                // Show knots if enabled
                if settings.showKnotsAlways && manager.windUnit != .knots {
                    HStack(spacing: 8) {
                        Image(systemName: "wind.snow")
                            .foregroundColor(.clear)
                        Text(String(format: "(%.1f knots)", settings.windSpeedInKnots(gust)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Temperature
            if let temp = manager.temperatureC {
                HStack(spacing: 8) {
                    Image(systemName: "thermometer")
                        .foregroundColor(.secondary)
                    Text(settings.temperatureString(temp))
                }
                .font(.body)
            }

            // Pressure
            if let pressure = manager.pressureHPa {
                HStack(spacing: 8) {
                    Image(systemName: "barometer")
                        .foregroundColor(.secondary)
                    Text("Pressure")
                        .foregroundColor(.secondary)
                    Text(settings.pressureString(pressure))
                }
                .font(.body)
            }

            // UV Index
            if let uv = manager.uvIndex {
                HStack(spacing: 8) {
                    Image(systemName: "sun.max")
                        .foregroundColor(.secondary)
                    Text("UV Index")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f — %@", uv, uvLevel(uv)))
                }
                .font(.body)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Drone Safety Alert")
                .font(.headline)

            Toggle("Enable wind alerts", isOn: $settings.enableWindAlerts)

            HStack {
                Text("Wind limit:")
                TextField("Limit", value: $settings.customDroneWindLimit, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("km/h")
                Text("(\(formattedWindLimit()))")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            HStack {
                Text("Alert sound")
                Spacer()
                Picker("Alert sound", selection: $settings.alertSound) {
                    ForEach(AlertSound.allCases) { sound in
                        Text(sound.rawValue).tag(sound)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
            }

            // Show custom sound file picker when Custom is selected
            if settings.alertSound == .custom {
                HStack {
                    Text("Sound file:")
                        .font(.caption)
                    if !settings.customSoundPath.isEmpty {
                        Text(customSoundFileName())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("None selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Choose...") {
                        selectCustomSound()
                    }
                    .buttonStyle(.bordered)
                }
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)

            // Mode picker
            HStack {
                Text("Mode")
                Spacer()
                Picker("Mode", selection: $manager.locationMode) {
                    Text("City").tag(LocationMode.cityName)
                    Text("Coords").tag(LocationMode.coordinates)
                    Text("World").tag(LocationMode.countryCity)
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            // Different inputs based on mode
            switch manager.locationMode {
            case .cityName:
                TextField("City", text: $manager.cityName)
                    .textFieldStyle(.roundedBorder)

            case .coordinates:
                HStack {
                    Text("Lat")
                    TextField("Latitude", value: $manager.latitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Lon")
                    TextField("Longitude", value: $manager.longitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                }

            case .countryCity:
                Picker("Country", selection: $manager.selectedCountry) {
                    ForEach(Array(manager.cityList.keys.sorted()), id: \.self) { country in
                        Text("\(manager.flagEmoji(for: country)) \(country)")
                            .tag(country)
                    }
                }

                Picker("City", selection: $manager.selectedCity) {
                    ForEach(manager.cityList[manager.selectedCountry] ?? [], id: \.self) { city in
                        Text(city).tag(city)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Display")
                .font(.headline)

            // Unit picker
            HStack {
                Text("Unit")
                Spacer()
                Picker("Units", selection: $manager.windUnit) {
                    ForEach(WindUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            // Temperature unit
            HStack {
                Spacer()
                Picker("Temperature", selection: $settings.temperatureUnit) {
                    ForEach(TemperatureUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            // Pressure unit
            HStack {
                Spacer()
                Picker("Pressure", selection: $settings.pressureUnit) {
                    ForEach(PressureUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            // Window width
            HStack {
                Text("Window width")
                Spacer()
                Picker("Window width", selection: $settings.windowWidth) {
                    ForEach(WindowWidth.allCases) { width in
                        Text(width.displayName).tag(width)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            // Recommended wind limits
            Button(action: {
                showWindLimits = true
            }) {
                HStack {
                    Image(systemName: "info.circle")
                    Text("Recommended wind limits")
                }
            }
            .buttonStyle(.link)
            .sheet(isPresented: $showWindLimits) {
                DroneWindLimitsView()
                    .environmentObject(manager)
            }

            // Dummy data toggle
            Toggle("Use dummy data", isOn: $manager.useDummyData)

            // Show knots always toggle
            Toggle("Always show wind in knots", isOn: $settings.showKnotsAlways)

            // Auto-refresh
            HStack {
                Text("Auto-refresh:")
                TextField("Minutes", value: $manager.refreshIntervalMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("min")
            }

            // Refresh button
            Button(action: {
                manager.refresh()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh now")
                }
            }
        }
    }
}

// MARK: - Next Hours Section

struct NextHoursSection: View {

    @EnvironmentObject var manager: WeatherManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next hours")
                .font(.headline)

            if manager.hourlyForecast.isEmpty {
                Text("No forecast data")
                    .foregroundColor(.secondary)
            } else {
                ForEach(manager.hourlyForecast) { entry in
                    HourlyRow(entry: entry)
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                // Time
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                Text(entry.label)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 50, alignment: .leading)

                // Wind icon
                Image(systemName: "wind")
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                // Wind speed
                if let speed = entry.windSpeed {
                    Text(String(format: "%.1f %@", speed, manager.windUnit.displayName))
                        .frame(width: 80, alignment: .leading)
                }

                // Gust
                if let gust = entry.windGust, let compass = entry.windDirectionCompass {
                    Text(String(format: "Gusts %.1f %@ %@", gust, manager.windUnit.displayName, compass))
                }

                Spacer()

                // Pressure
                if let pressure = entry.pressureHPa {
                    Text(String(format: "· %.0f hPa", pressure))
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .font(.body)

            // Show knots if enabled
            if settings.showKnotsAlways && manager.windUnit != .knots {
                HStack(spacing: 12) {
                    Spacer()
                        .frame(width: 16)
                    Spacer()
                        .frame(width: 50)
                    Spacer()
                        .frame(width: 16)

                    if let speed = entry.windSpeed {
                        Text(String(format: "(%.1f knots", settings.convertToKnots(speed, from: manager.windUnit)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    }

                    if let gust = entry.windGust {
                        Text(String(format: "· %.1f knots)", settings.convertToKnots(gust, from: manager.windUnit)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
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
        VStack(alignment: .leading, spacing: 12) {
            Text("External links")
                .font(.headline)

            Text("note: External sources")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                LinkButton(title: "Open in The Weather Channel", icon: "link") {
                    openWeatherChannel()
                }
                Button(action: {
                    showICAOList = true
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Australian ICAO List")
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.link)
            }

            Text("Australian Airspace - official sources")
                .font(.headline)
                .padding(.top, 8)

            Text("note: Official external sources")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                LinkButton(title: "Open AIP", icon: "link", url: "https://www.airservicesaustralia.com/aip")
                LinkButton(title: "Open NAIPS$ (NOTAMs/Briefing) — paid service", icon: "link", url: "https://www.airservicesaustralia.com/naips/Account/Logon")
                LinkButton(title: "Open CASA RPAS Gui...", icon: "link", url: "https://www.casa.gov.au/drones")
                LinkButton(title: "BOM Weather", icon: "link", url: "http://www.bom.gov.au")
                LinkButton(title: "Weatherzone Radar", icon: "link", url: "https://www.weatherzone.com.au/radar")
            }

            Text("disclaimer: Airspace and NOTAMs change frequently. Always check official sources before flight.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            HStack(spacing: 16) {
                LinkButton(title: "ICAO Lookup", icon: "magnifyingglass", url: "https://ourairports.com/")
                LinkButton(title: "FlightAware", icon: "airplane", url: "https://www.flightaware.com")
            }

            // Pro Pilots Button
            Button(action: {
                showProPilots = true
            }) {
                HStack {
                    Image(systemName: "play.circle")
                    Text("Pro pilots I recommend")
                }
            }
            .buttonStyle(.link)
            .padding(.top, 8)
            .sheet(isPresented: $showProPilots) {
                ProPilotsView()
            }
            .sheet(isPresented: $showICAOList) {
                AustralianICAOView()
            }

            Divider()
                .padding(.top, 8)

            // Attribution
            VStack(alignment: .leading, spacing: 4) {
                Text("This app is free and distributable and the github source is available under the MIT license by db.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Button(action: {
                    if let url = URL(string: "https://github.com/FPV-dB/windbar-recovery") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("MIT License Open-Source by db 2026 (https://github.com/FPV-dB/windbar-recovery)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
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
            HStack {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.link)
    }
}
