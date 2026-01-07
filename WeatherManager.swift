//
//  WeatherManager.swift
//  WindBar v1.3
//

import Foundation
import Combine
import CoreLocation

// 👉 PASTE THE ENUM RIGHT HERE
enum WindUnit: String, CaseIterable, Identifiable, Hashable, Codable {
    case kmh
    case mph
    case ms
    case knots

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kmh: return "km/h"
        case .mph: return "mph"
        case .ms:  return "m/s"
        case .knots: return "knots"
        }
    }
}

// 👉 DO NOT paste it anywhere else.
// ----------------------------------

// MARK: - Wind Unit Enum

// enum WindUnit: String, CaseIterable, Identifiable, Codable {
//    case kmh, mph, ms, knots

// var id: String { rawValue }

//    var display: String {
//        switch self {
//        case .kmh:   return "km/h"
//        case .mph:   return "mph"
//        case .ms:    return "m/s"
//        case .knots: return "knots"
//        }
//    }
// }

// MARK: - Location Mode

enum LocationMode: String, CaseIterable, Identifiable {
    case cityName
    case coordinates
    case countryCity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cityName:     return "City"
        case .coordinates:  return "Coords"
        case .countryCity:  return "Country/City"
        }
    }
}

// MARK: - Hourly Entry

struct HourlyEntry: Identifiable {
    let id = UUID()
    let label: String    // e.g. "14:00"
    let tempC: Double?
    let windSpeed: Double?
    let windGust: Double?
    let windDirectionDeg: Double?
    let windDirectionCompass: String?
    let pressureHPa: Double?
}

@MainActor
final class WeatherManager: NSObject, ObservableObject {

    // MARK: - Published

    @Published var useDummyData: Bool = false {
        didSet { refresh() }
    }

    @Published var windUnit: WindUnit = .kmh {
        didSet {
            UserDefaults.standard.set(windUnit.rawValue, forKey: "windUnit")
            refresh()
        }
    }

    @Published var locationMode: LocationMode = .cityName {
        didSet {
            UserDefaults.standard.set(locationMode.rawValue, forKey: "locationMode")
            refresh()
        }
    }

    @Published var cityName: String = "Adelaide" {
        didSet {
            UserDefaults.standard.set(cityName, forKey: "cityName")
        }
    }

    @Published var latitude: Double? {
        didSet {
            if let lat = latitude {
                UserDefaults.standard.set(lat, forKey: "latitude")
            }
        }
    }
    @Published var longitude: Double? {
        didSet {
            if let lon = longitude {
                UserDefaults.standard.set(lon, forKey: "longitude")
            }
        }
    }

    @Published var selectedCountry: String = "Australia" {
        didSet {
            UserDefaults.standard.set(selectedCountry, forKey: "selectedCountry")
            if let first = cityList[selectedCountry]?.first {
                selectedCity = first
            }
        }
    }
    @Published var selectedCity: String = "Adelaide" {
        didSet {
            UserDefaults.standard.set(selectedCity, forKey: "selectedCity")
        }
    }

    @Published var windSpeedKmh: Double?
    @Published var windGustKmh: Double?
    @Published var windDirectionDeg: Double?
    @Published var windDirectionCompass: String?
    @Published var temperatureC: Double?
    @Published var pressureHPa: Double?
    @Published var uvIndex: Double?
    @Published var lastUpdated: Date?

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // What appears in the macOS menu bar item
    @Published var windSpeedDisplayed: String?

    // Auto-refresh interval in minutes (min 5)
    @Published var refreshIntervalMinutes: Int = 15 {
        didSet {
            if refreshIntervalMinutes < 5 { refreshIntervalMinutes = 5 }
            scheduleAutoRefresh()
        }
    }

    // Hourly forecast
    @Published var hourlyForecast: [HourlyEntry] = []

    // MARK: - Private

    private let locationManager = CLLocationManager()
    private let urlSession = URLSession(configuration: .default)
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: AnyCancellable?

    // Countries + cities
    let cityList: [String: [String]] = [
        "Australia": ["Adelaide","Melbourne","Sydney","Perth","Brisbane","Hobart","Darwin","Canberra","Gold Coast","Newcastle","Wollongong","Cairns","Townsville","Geelong"],
        "New Zealand": ["Auckland","Wellington","Christchurch","Hamilton","Tauranga","Dunedin","Queenstown","Rotorua"],
        "USA": ["New York","Los Angeles","Chicago","San Francisco","Seattle","Miami","Houston","Dallas","Boston","Denver","Atlanta","Phoenix","Philadelphia","Portland","Austin","Las Vegas"],
        "UK": ["London","Manchester","Liverpool","Birmingham","Edinburgh","Glasgow","Bristol","Leeds","Sheffield","Cardiff","Belfast","Newcastle"],
        "Canada": ["Toronto","Vancouver","Montreal","Calgary","Ottawa","Edmonton","Winnipeg","Quebec City","Halifax","Victoria"],
        "Germany": ["Berlin","Hamburg","Munich","Frankfurt","Cologne","Stuttgart","Düsseldorf","Dortmund","Leipzig"],
        "France": ["Paris","Lyon","Marseille","Nice","Bordeaux","Toulouse","Strasbourg","Nantes","Lille"],
        "Japan": ["Tokyo","Osaka","Kyoto","Nagoya","Sapporo","Fukuoka","Yokohama","Kobe","Hiroshima"],
        "Spain": ["Madrid","Barcelona","Valencia","Seville","Bilbao","Málaga","Granada","Alicante"],
        "Italy": ["Rome","Milan","Naples","Turin","Florence","Venice","Bologna","Palermo"],
        "Netherlands": ["Amsterdam","Rotterdam","The Hague","Utrecht","Eindhoven","Groningen","Maastricht"],
        "Switzerland": ["Zurich","Geneva","Basel","Bern","Lausanne","Lucerne","Interlaken"],
        "Norway": ["Oslo","Bergen","Trondheim","Stavanger","Tromsø","Kristiansand"],
        "Sweden": ["Stockholm","Gothenburg","Malmö","Uppsala","Västerås","Örebro"],
        "Denmark": ["Copenhagen","Aarhus","Odense","Aalborg","Esbjerg"],
        "Ireland": ["Dublin","Cork","Galway","Limerick","Waterford"],
        "South Korea": ["Seoul","Busan","Incheon","Daegu","Daejeon","Gwangju"],
        "China": ["Beijing","Shanghai","Guangzhou","Shenzhen","Chengdu","Hong Kong","Hangzhou","Xi'an"],
        "Singapore": ["Singapore"],
        "Thailand": ["Bangkok","Chiang Mai","Phuket","Pattaya","Krabi"],
        "India": ["Mumbai","Delhi","Bangalore","Hyderabad","Chennai","Kolkata","Pune","Ahmedabad"],
        "UAE": ["Dubai","Abu Dhabi","Sharjah","Ajman"],
        "South Africa": ["Cape Town","Johannesburg","Durban","Pretoria","Port Elizabeth"],
        "Brazil": ["São Paulo","Rio de Janeiro","Brasília","Salvador","Fortaleza","Belo Horizonte"],
        "Argentina": ["Buenos Aires","Córdoba","Rosario","Mendoza","Mar del Plata"],
        "Mexico": ["Mexico City","Guadalajara","Monterrey","Cancún","Tijuana","Puebla"]
    ]

    override init() {
        super.init()
        locationManager.delegate = self

        // Load saved preferences
        if let savedWindUnit = UserDefaults.standard.string(forKey: "windUnit"),
           let unit = WindUnit(rawValue: savedWindUnit) {
            windUnit = unit
        }

        if let savedLocationMode = UserDefaults.standard.string(forKey: "locationMode"),
           let mode = LocationMode(rawValue: savedLocationMode) {
            locationMode = mode
        }

        if let savedCity = UserDefaults.standard.string(forKey: "cityName") {
            cityName = savedCity
        }

        if UserDefaults.standard.object(forKey: "latitude") != nil {
            latitude = UserDefaults.standard.double(forKey: "latitude")
        }

        if UserDefaults.standard.object(forKey: "longitude") != nil {
            longitude = UserDefaults.standard.double(forKey: "longitude")
        }

        if let savedCountry = UserDefaults.standard.string(forKey: "selectedCountry") {
            selectedCountry = savedCountry
        }

        if let savedCity = UserDefaults.standard.string(forKey: "selectedCity") {
            selectedCity = savedCity
        }

        scheduleAutoRefresh()
    }

    deinit {
        refreshTimer?.cancel()
    }

    // MARK: - Public API

    func refresh() {
        errorMessage = nil

        if useDummyData {
            loadDummy()
        } else {
            Task { await fetchLive() }
        }
    }

    func useDeviceLocation() {
        errorMessage = nil
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func flagEmoji(for country: String) -> String {
        switch country {
        case "Australia":    return "🇦🇺"
        case "New Zealand":  return "🇳🇿"
        case "USA":          return "🇺🇸"
        case "UK":           return "🇬🇧"
        case "Canada":       return "🇨🇦"
        case "Germany":      return "🇩🇪"
        case "France":       return "🇫🇷"
        case "Japan":        return "🇯🇵"
        case "Spain":        return "🇪🇸"
        case "Italy":        return "🇮🇹"
        case "Netherlands":  return "🇳🇱"
        case "Switzerland":  return "🇨🇭"
        case "Norway":       return "🇳🇴"
        case "Sweden":       return "🇸🇪"
        case "Denmark":      return "🇩🇰"
        case "Ireland":      return "🇮🇪"
        case "South Korea":  return "🇰🇷"
        case "China":        return "🇨🇳"
        case "Singapore":    return "🇸🇬"
        case "Thailand":     return "🇹🇭"
        case "India":        return "🇮🇳"
        case "UAE":          return "🇦🇪"
        case "South Africa": return "🇿🇦"
        case "Brazil":       return "🇧🇷"
        case "Argentina":    return "🇦🇷"
        case "Mexico":       return "🇲🇽"
        default:             return ""
        }
    }

    // MARK: - Auto Refresh

    private func scheduleAutoRefresh() {
        refreshTimer?.cancel()
        let minutes = max(refreshIntervalMinutes, 5)
        let interval = TimeInterval(minutes * 60)

        refreshTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    // MARK: - Dummy Data

    private func loadDummy() {
        isLoading = false
        errorMessage = nil

        windSpeedKmh = 8.8
        windGustKmh = 16.6
        windDirectionDeg = 202.0
        windDirectionCompass = "SSW"
        temperatureC = 24.0
        pressureHPa = 1009.0
        uvIndex = 0.0
        lastUpdated = Date()

        // simple fake hourly
        hourlyForecast = (0..<6).map { i in
            let hour = (Calendar.current.component(.hour, from: Date()) + i) % 24
            return HourlyEntry(
                label: String(format: "%02d:00", hour),
                tempC: 24.0 + Double(i) * 0.5,
                windSpeed: 8.8 + Double(i) * 1.5,
                windGust: 16.6 + Double(i) * 0.8,
                windDirectionDeg: 202.0,
                windDirectionCompass: "SSW",
                pressureHPa: 1009.0 - Double(i) * 0.5
            )
        }

        updateMenuBarSpeed()
    }

    // MARK: - Networking

    private func fetchLive() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var lat = latitude
            var lon = longitude

            switch locationMode {
            case .cityName:
                (lat, lon) = try await geocode(cityName)

            case .coordinates:
                guard let la = latitude, let lo = longitude else {
                    errorMessage = "Enter valid coordinates."
                    return
                }
                lat = la
                lon = lo

            case .countryCity:
                (lat, lon) = try await geocode(selectedCity)
            }

            guard let finalLat = lat, let finalLon = lon else { return }

            var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            comps.queryItems = [
                URLQueryItem(name: "latitude", value: "\(finalLat)"),
                URLQueryItem(name: "longitude", value: "\(finalLon)"),
                URLQueryItem(name: "current", value: "temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,surface_pressure,uv_index"),
                URLQueryItem(name: "hourly", value: "temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,surface_pressure"),
                URLQueryItem(name: "forecast_days", value: "1"),
                URLQueryItem(name: "timezone", value: "auto"),
                URLQueryItem(name: "windspeed_unit", value: windUnit.rawValue)
            ]

            let (data, response) = try await urlSession.data(from: comps.url!)

            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                errorMessage = "Weather service error."
                return
            }

            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            apply(openMeteo: decoded)

        } catch {
            errorMessage = "Failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Apply

    private func apply(openMeteo: OpenMeteoResponse) {
        let current = openMeteo.current
        windSpeedKmh = current.wind_speed_10m
        windGustKmh = current.wind_gusts_10m
        windDirectionDeg = current.wind_direction_10m
        windDirectionCompass = compassDirection(from: current.wind_direction_10m)
        temperatureC = current.temperature_2m
        pressureHPa = current.surface_pressure
        uvIndex = current.uv_index
        lastUpdated = Date()

        // Hourly conversion (next ~6 points)
        if let h = openMeteo.hourly {
            var entries: [HourlyEntry] = []
            let count = min(6, h.time.count)

            for i in 0..<count {
                let raw = h.time[i]
                let label: String
                if let tPart = raw.split(separator: "T").last {
                    label = String(tPart.prefix(5))  // "HH:MM"
                } else {
                    label = raw
                }

                let entry = HourlyEntry(
                    label: label,
                    tempC: h.temperature_2m?[safe: i],
                    windSpeed: h.wind_speed_10m?[safe: i],
                    windGust: h.wind_gusts_10m?[safe: i],
                    windDirectionDeg: h.wind_direction_10m?[safe: i],
                    windDirectionCompass: compassDirection(from: h.wind_direction_10m?[safe: i]),
                    pressureHPa: h.surface_pressure?[safe: i]
                )
                entries.append(entry)
            }
            hourlyForecast = entries
        } else {
            hourlyForecast = []
        }

        updateMenuBarSpeed()
    }

    private func compassDirection(from degrees: Double?) -> String? {
        guard let deg = degrees else { return nil }
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((deg + 11.25) / 22.5) % 16
        return directions[index]
    }

    private func updateMenuBarSpeed() {
        guard let speed = windSpeedKmh else {
            windSpeedDisplayed = "—"
            return
        }
        windSpeedDisplayed = "\(Int(speed)) \(windUnit.displayName)"
    }

    // MARK: - Geocoding

    private func geocode(_ name: String) async throws -> (Double, Double) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw NSError(domain: "Empty", code: 1) }

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed

        let url = URL(string:
            "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=1"
        )!

        let (data, _) = try await urlSession.data(from: url)

        struct GeoResponse: Decodable {
            struct Item: Decodable { let latitude: Double; let longitude: Double }
            let results: [Item]?
        }

        let decoded = try JSONDecoder().decode(GeoResponse.self, from: data)
        guard let first = decoded.results?.first else {
            throw NSError(domain: "No results", code: 2)
        }
        return (first.latitude, first.longitude)
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Open Meteo Models

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double?
        let wind_speed_10m: Double?
        let wind_gusts_10m: Double?
        let wind_direction_10m: Double?
        let surface_pressure: Double?
        let uv_index: Double?
    }
    struct Hourly: Decodable {
        let time: [String]
        let temperature_2m: [Double]?
        let wind_speed_10m: [Double]?
        let wind_gusts_10m: [Double]?
        let wind_direction_10m: [Double]?
        let surface_pressure: [Double]?
    }

    let current: Current
    let hourly: Hourly?
}

// MARK: - CLLocationManagerDelegate

extension WeatherManager: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.latitude = loc.coordinate.latitude
            self.longitude = loc.coordinate.longitude
            self.locationMode = .coordinates
            self.refresh()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
}
