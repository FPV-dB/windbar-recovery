//
//  MainWindBarView.swift
//  WindBar
//

import SwiftUI

struct MainWindBarView: View {

    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Current Weather Section
                CurrentWeatherSection()

                Divider()

                // MARK: - Drone Safety Alert
                DroneAlertSection()

                Divider()

                // MARK: - Location Section
                LocationSection()

                Divider()

                // MARK: - Display Settings
                DisplaySection()

                Divider()

                // MARK: - Next Hours
                NextHoursSection()

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
                }
            }

            // Trend (placeholder for now)
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.secondary)
                Text("Trend:")
                    .foregroundColor(.secondary)
                Image(systemName: "arrow.right")
                Text("Steady (20 min)")
            }
            .font(.body)

            // Gusts
            if let gust = manager.windGustKmh, let compass = manager.windDirectionCompass {
                HStack(spacing: 8) {
                    Image(systemName: "wind.snow")
                        .foregroundColor(.secondary)
                    Text("Gusts")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f %@ %@", gust, manager.windUnit.displayName, compass))
                }
                .font(.body)
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

            // Pressure trend (placeholder)
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.secondary)
                Text("Pressure trend:")
                    .foregroundColor(.secondary)
                Image(systemName: "arrow.right")
                Text("Steady (20 min)")
            }
            .font(.caption)

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
}

// MARK: - Drone Alert Section

struct DroneAlertSection: View {

    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drone Safety Alert")
                .font(.headline)

            Toggle("Enable wind alerts", isOn: $settings.enableWindAlerts)

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
        }
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
                Text("Temperature")
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
                Text("Pressure")
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

            // Recommended wind limits (placeholder)
            Button(action: {}) {
                HStack {
                    Image(systemName: "info.circle")
                    Text("Recommended wind limits")
                }
            }
            .buttonStyle(.link)

            // Dummy data toggle
            Toggle("Use dummy data", isOn: $manager.useDummyData)

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
    }
}

// MARK: - External Links Section

struct ExternalLinksSection: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("External links")
                .font(.headline)

            Text("note: External sources")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                LinkButton(title: "Open in The Weather Channel", icon: "link")
                LinkButton(title: "Australian ICAO List", icon: "list.bullet")
            }

            Text("Australian Airspace - official sources")
                .font(.headline)
                .padding(.top, 8)

            Text("note: Official external sources")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                LinkButton(title: "Open AIP", icon: "link")
                LinkButton(title: "Open NAIPS (NOTAMs/Briefing) — paid service", icon: "link")
                LinkButton(title: "Open CASA RPAS Gui...", icon: "link")
                LinkButton(title: "BOM Weather", icon: "link")
                LinkButton(title: "Weatherzone Radar", icon: "link")
            }

            Text("disclaimer: Airspace and NOTAMs change frequently. Always check official sources before flight.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            HStack(spacing: 16) {
                LinkButton(title: "ICAO Lookup", icon: "magnifyingglass")
                LinkButton(title: "FlightAware", icon: "airplane")
            }
        }
    }
}

struct LinkButton: View {
    let title: String
    let icon: String

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.link)
    }
}
