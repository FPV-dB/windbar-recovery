//
//  AppSettings.swift
//  WindBar
//
//  Copyright © 2026 db. All rights reserved.
//  Licensed under the MIT License.
//  Please attribute me if you use my work.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Icon Style

enum IconStyle: String, CaseIterable, Identifiable, Codable {
    case windAndArrow = "Wind + Arrow"
    case arrowOnly = "Arrow Only"
    case windOnly = "Wind Only"
    case compact = "Compact"

    var id: String { rawValue }
}

// MARK: - Temperature Unit

enum TemperatureUnit: String, CaseIterable, Identifiable, Codable {
    case celsius = "°C"
    case fahrenheit = "°F"

    var id: String { rawValue }
}

// MARK: - Pressure Unit

enum PressureUnit: String, CaseIterable, Identifiable, Codable {
    case hPa
    case mbar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hPa: return "hPa"
        case .mbar: return "mbar"
        }
    }
}

// MARK: - Window Width

enum WindowWidth: String, CaseIterable, Identifiable, Codable {
    case compact
    case regular
    case wide

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var width: CGFloat {
        switch self {
        case .compact: return 280
        case .regular: return 360
        case .wide: return 540
        }
    }
}

// MARK: - Alert Sound

enum AlertSound: String, CaseIterable, Identifiable, Codable {
    case ping = "Ping"
    case pop = "Pop"
    case hero = "Hero"
    case submarine = "Submarine"
    case none = "None"

    var id: String { rawValue }
}

// MARK: - App Settings

@MainActor
class AppSettings: ObservableObject {

    @AppStorage("iconStyle") private var iconStyleRaw: String = IconStyle.windAndArrow.rawValue
    @Published var iconStyle: IconStyle = .windAndArrow {
        didSet { iconStyleRaw = iconStyle.rawValue }
    }

    @AppStorage("windowWidth") private var windowWidthRaw: String = WindowWidth.wide.rawValue
    @Published var windowWidth: WindowWidth = .wide {
        didSet { windowWidthRaw = windowWidth.rawValue }
    }

    @AppStorage("enableWindAlerts") var enableWindAlerts: Bool = false
    @AppStorage("alertSound") private var alertSoundRaw: String = AlertSound.ping.rawValue
    @Published var alertSound: AlertSound = .ping {
        didSet { alertSoundRaw = alertSound.rawValue }
    }
    @AppStorage("windAlertThreshold") var windAlertThreshold: Double = 25.0
    @AppStorage("customDroneWindLimit") var customDroneWindLimit: Double = 25.0

    // Display preferences
    @AppStorage("temperatureUnit") private var temperatureUnitRaw: String = TemperatureUnit.celsius.rawValue
    @Published var temperatureUnit: TemperatureUnit = .celsius {
        didSet { temperatureUnitRaw = temperatureUnit.rawValue }
    }

    @AppStorage("pressureUnit") private var pressureUnitRaw: String = PressureUnit.hPa.rawValue
    @Published var pressureUnit: PressureUnit = .hPa {
        didSet { pressureUnitRaw = pressureUnit.rawValue }
    }

    @AppStorage("showKnotsAlways") var showKnotsAlways: Bool = false

    // Load saved values on init
    init() {
        if let saved = IconStyle(rawValue: iconStyleRaw) {
            iconStyle = saved
        }
        if let saved = WindowWidth(rawValue: windowWidthRaw) {
            windowWidth = saved
        }
        if let saved = AlertSound(rawValue: alertSoundRaw) {
            alertSound = saved
        }
        if let saved = TemperatureUnit(rawValue: temperatureUnitRaw) {
            temperatureUnit = saved
        }
        if let saved = PressureUnit(rawValue: pressureUnitRaw) {
            pressureUnit = saved
        }
    }

    // Convert temperature
    func convertTemperature(_ celsius: Double?) -> Double? {
        guard let c = celsius else { return nil }
        switch temperatureUnit {
        case .celsius:
            return c
        case .fahrenheit:
            return c * 9/5 + 32
        }
    }

    func convertPressure(_ hPa: Double?) -> Double? {
        guard let p = hPa else { return nil }
        // hPa and mbar are actually the same value
        return p
    }

    func temperatureString(_ celsius: Double?) -> String {
        guard let temp = convertTemperature(celsius) else { return "—" }
        return String(format: "%.1f%@", temp, temperatureUnit.rawValue)
    }

    func pressureString(_ hPa: Double?) -> String {
        guard let pressure = convertPressure(hPa) else { return "—" }
        return String(format: "%.0f %@", pressure, pressureUnit.displayName)
    }

    // Convert km/h to knots
    func windSpeedInKnots(_ kmh: Double) -> Double {
        return kmh * 0.539957
    }

    // Convert wind speed from any unit to knots
    func convertToKnots(_ speed: Double, from unit: WindUnit) -> Double {
        // First convert to km/h, then to knots
        let kmh: Double
        switch unit {
        case .kmh:
            kmh = speed
        case .mph:
            kmh = speed / 0.621371
        case .ms:
            kmh = speed * 3.6
        case .knots:
            return speed  // Already in knots
        }
        return kmh * 0.539957
    }
}
