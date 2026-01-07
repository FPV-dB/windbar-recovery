//
//  AppSettings.swift
//  WindBar
//

import Foundation
import SwiftUI
import Combine

// MARK: - Icon Style

enum IconStyle: String, CaseIterable, Identifiable, Codable {
    case windAndArrow = "Wind + Arrow"
    case arrowOnly = "Arrow Only"
    case windOnly = "Wind Only"

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

    @Published var iconStyle: IconStyle = .windAndArrow
    @Published var windowWidth: WindowWidth = .wide
    @Published var enableWindAlerts: Bool = false
    @Published var alertSound: AlertSound = .ping
    @Published var windAlertThreshold: Double = 25.0 // in current wind unit

    // Display preferences
    @Published var temperatureUnit: TemperatureUnit = .celsius
    @Published var pressureUnit: PressureUnit = .hPa

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
}
