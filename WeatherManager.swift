//
//  WeatherManager.swift
//  WindBar
//
//  Copyright © 2026 db. All rights reserved.
//  Licensed under the MIT License.
//  Please attribute me if you use my work.
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
        "Australia": ["Adelaide","Melbourne","Sydney","Perth","Brisbane","Hobart","Darwin","Canberra","Gold Coast","Newcastle","Wollongong","Cairns","Townsville","Geelong","Launceston","Albury","Ballarat","Bendigo","Mackay","Rockhampton"],
        "New Zealand": ["Auckland","Wellington","Christchurch","Hamilton","Tauranga","Dunedin","Queenstown","Rotorua","Napier","Nelson","Palmerston North","Invercargill"],
        "USA": ["New York","Los Angeles","Chicago","San Francisco","Seattle","Miami","Houston","Dallas","Boston","Denver","Atlanta","Phoenix","Philadelphia","Portland","Austin","Las Vegas","San Diego","San Jose","Detroit","Minneapolis","Tampa","Orlando","Charlotte","Nashville","Salt Lake City","Honolulu","Anchorage"],
        "UK": ["London","Manchester","Liverpool","Birmingham","Edinburgh","Glasgow","Bristol","Leeds","Sheffield","Cardiff","Belfast","Newcastle","Nottingham","Southampton","Leicester","Brighton","Aberdeen","Cambridge","Oxford","York","Norwich"],
        "Canada": ["Toronto","Vancouver","Montreal","Calgary","Ottawa","Edmonton","Winnipeg","Quebec City","Halifax","Victoria","Saskatoon","Regina","Kelowna","Thunder Bay","Whitehorse","Yellowknife"],
        "Germany": ["Berlin","Hamburg","Munich","Frankfurt","Cologne","Stuttgart","Düsseldorf","Dortmund","Leipzig","Dresden","Nuremberg","Hanover","Bremen","Heidelberg","Freiburg"],
        "France": ["Paris","Lyon","Marseille","Nice","Bordeaux","Toulouse","Strasbourg","Nantes","Lille","Rennes","Grenoble","Montpellier","Cannes","Biarritz","Chamonix"],
        "Japan": ["Tokyo","Osaka","Kyoto","Nagoya","Sapporo","Fukuoka","Yokohama","Kobe","Hiroshima","Sendai","Nara","Okinawa","Kamakura","Takayama"],
        "Spain": ["Madrid","Barcelona","Valencia","Seville","Bilbao","Málaga","Granada","Alicante","Zaragoza","Palma","San Sebastian","Córdoba","Toledo","Salamanca"],
        "Italy": ["Rome","Milan","Naples","Turin","Florence","Venice","Bologna","Palermo","Genoa","Verona","Pisa","Siena","Como","Rimini","Sorrento"],
        "Netherlands": ["Amsterdam","Rotterdam","The Hague","Utrecht","Eindhoven","Groningen","Maastricht","Haarlem","Leiden","Delft"],
        "Switzerland": ["Zurich","Geneva","Basel","Bern","Lausanne","Lucerne","Interlaken","Zermatt","St. Moritz","Lugano"],
        "Norway": ["Oslo","Bergen","Trondheim","Stavanger","Tromsø","Kristiansand","Ålesund","Bodø","Drammen"],
        "Sweden": ["Stockholm","Gothenburg","Malmö","Uppsala","Västerås","Örebro","Lund","Umeå","Helsingborg"],
        "Denmark": ["Copenhagen","Aarhus","Odense","Aalborg","Esbjerg","Roskilde","Kolding"],
        "Ireland": ["Dublin","Cork","Galway","Limerick","Waterford","Killarney","Kilkenny","Derry"],
        "South Korea": ["Seoul","Busan","Incheon","Daegu","Daejeon","Gwangju","Ulsan","Jeju","Suwon"],
        "China": ["Beijing","Shanghai","Guangzhou","Shenzhen","Chengdu","Hong Kong","Hangzhou","Xi'an","Wuhan","Chongqing","Tianjin","Nanjing","Suzhou","Macau"],
        "Singapore": ["Singapore"],
        "Thailand": ["Bangkok","Chiang Mai","Phuket","Pattaya","Krabi","Koh Samui","Hua Hin","Ayutthaya"],
        "India": ["Mumbai","Delhi","Bangalore","Hyderabad","Chennai","Kolkata","Pune","Ahmedabad","Jaipur","Goa","Kochi","Chandigarh"],
        "UAE": ["Dubai","Abu Dhabi","Sharjah","Ajman","Ras Al Khaimah","Fujairah"],
        "South Africa": ["Cape Town","Johannesburg","Durban","Pretoria","Port Elizabeth","Bloemfontein","Kimberley","Knysna"],
        "Brazil": ["São Paulo","Rio de Janeiro","Brasília","Salvador","Fortaleza","Belo Horizonte","Manaus","Curitiba","Porto Alegre","Recife"],
        "Argentina": ["Buenos Aires","Córdoba","Rosario","Mendoza","Mar del Plata","Salta","Bariloche","Ushuaia"],
        "Mexico": ["Mexico City","Guadalajara","Monterrey","Cancún","Tijuana","Puebla","Playa del Carmen","Puerto Vallarta","Oaxaca","Mérida"],
        "Austria": ["Vienna","Salzburg","Innsbruck","Graz","Linz","Hallstatt"],
        "Belgium": ["Brussels","Antwerp","Bruges","Ghent","Leuven","Liège"],
        "Poland": ["Warsaw","Kraków","Gdańsk","Wrocław","Poznań","Łódź"],
        "Czech Republic": ["Prague","Brno","Ostrava","Plzeň","Karlovy Vary"],
        "Portugal": ["Lisbon","Porto","Faro","Coimbra","Madeira","Azores"],
        "Greece": ["Athens","Thessaloniki","Santorini","Mykonos","Crete","Rhodes"],
        "Turkey": ["Istanbul","Ankara","Izmir","Antalya","Bodrum","Cappadocia"],
        "Russia": ["Moscow","St. Petersburg","Vladivostok","Sochi","Yekaterinburg","Kazan"],
        "Finland": ["Helsinki","Tampere","Turku","Oulu","Rovaniemi","Espoo"],
        "Iceland": ["Reykjavik","Akureyri","Keflavik","Vik"],
        "Croatia": ["Zagreb","Split","Dubrovnik","Pula","Zadar"],
        "Hungary": ["Budapest","Debrecen","Szeged","Pécs"],
        "Romania": ["Bucharest","Cluj-Napoca","Timișoara","Brașov"],
        "Israel": ["Tel Aviv","Jerusalem","Haifa","Eilat"],
        "Egypt": ["Cairo","Alexandria","Luxor","Aswan","Sharm el-Sheikh"],
        "Morocco": ["Marrakech","Casablanca","Fez","Rabat","Tangier"],
        "Kenya": ["Nairobi","Mombasa","Kisumu","Nakuru"],
        "Nigeria": ["Lagos","Abuja","Kano","Ibadan","Port Harcourt"],
        "Vietnam": ["Hanoi","Ho Chi Minh City","Da Nang","Hoi An","Nha Trang"],
        "Indonesia": ["Jakarta","Bali","Surabaya","Bandung","Yogyakarta"],
        "Malaysia": ["Kuala Lumpur","Penang","Johor Bahru","Malacca","Langkawi"],
        "Philippines": ["Manila","Cebu","Davao","Boracay","Palawan"],
        "Taiwan": ["Taipei","Kaohsiung","Taichung","Tainan","Hualien"],
        "Chile": ["Santiago","Valparaíso","Viña del Mar","Punta Arenas","Atacama"],
        "Peru": ["Lima","Cusco","Arequipa","Machu Picchu"],
        "Colombia": ["Bogotá","Medellín","Cartagena","Cali","Barranquilla"],
        "Costa Rica": ["San José","Tamarindo","Monteverde","Puerto Viejo"],
        "Panama": ["Panama City","Bocas del Toro","Boquete"],
        "Qatar": ["Doha","Al Wakrah"],
        "Saudi Arabia": ["Riyadh","Jeddah","Mecca","Medina"],
        "Pakistan": ["Karachi","Lahore","Islamabad","Peshawar"],
        "Bangladesh": ["Dhaka","Chittagong","Sylhet"],
        "Sri Lanka": ["Colombo","Kandy","Galle","Jaffna"],
        "Algeria": ["Algiers","Oran","Constantine","Annaba"],
        "Tunisia": ["Tunis","Sfax","Sousse","Bizerte"],
        "Libya": ["Tripoli","Benghazi","Misrata"],
        "Ethiopia": ["Addis Ababa","Dire Dawa","Mekelle","Bahir Dar"],
        "Tanzania": ["Dar es Salaam","Dodoma","Arusha","Mwanza","Zanzibar"],
        "Uganda": ["Kampala","Entebbe","Jinja","Mbarara"],
        "Ghana": ["Accra","Kumasi","Tamale","Cape Coast"],
        "Senegal": ["Dakar","Thiès","Saint-Louis","Touba"],
        "Ivory Coast": ["Abidjan","Yamoussoukro","Bouaké","San-Pédro"],
        "Zimbabwe": ["Harare","Bulawayo","Mutare","Gweru"],
        "Zambia": ["Lusaka","Kitwe","Ndola","Livingstone"],
        "Botswana": ["Gaborone","Francistown","Maun","Kasane"],
        "Namibia": ["Windhoek","Swakopmund","Walvis Bay","Oshakati"],
        "Mozambique": ["Maputo","Beira","Nampula","Matola"],
        "Madagascar": ["Antananarivo","Toamasina","Antsirabe","Mahajanga"],
        "Mauritius": ["Port Louis","Curepipe","Quatre Bornes","Flic en Flac"],
        "Seychelles": ["Victoria","Anse Royale","Beau Vallon"],
        "Réunion": ["Saint-Denis","Saint-Paul","Saint-Pierre","Le Tampon"],
        "Antarctica": ["McMurdo Station","Palmer Station","Rothera Station","Casey Station","Davis Station","Mawson Station","Scott Base","Vostok Station"],
        "Greenland": ["Nuuk","Ilulissat","Sisimiut","Qaqortoq","Kangerlussuaq"],
        "Svalbard": ["Longyearbyen","Ny-Ålesund","Barentsburg"],
        "Faroe Islands": ["Tórshavn","Klaksvík","Runavík"],
        "Jordan": ["Amman","Petra","Aqaba","Jerash","Dead Sea"],
        "Lebanon": ["Beirut","Tripoli","Sidon","Byblos"],
        "Oman": ["Muscat","Salalah","Sohar","Nizwa"],
        "Kuwait": ["Kuwait City","Hawally","Salmiya","Jahra"],
        "Bahrain": ["Manama","Muharraq","Riffa","Hamad Town"],
        "Azerbaijan": ["Baku","Ganja","Sumqayit","Lankaran"],
        "Kazakhstan": ["Almaty","Nur-Sultan","Shymkent","Karaganda"],
        "Uzbekistan": ["Tashkent","Samarkand","Bukhara","Khiva"],
        "Mongolia": ["Ulaanbaatar","Erdenet","Darkhan","Choir"],
        "Nepal": ["Kathmandu","Pokhara","Lalitpur","Bhaktapur"],
        "Bhutan": ["Thimphu","Paro","Punakha","Phuentsholing"],
        "Myanmar": ["Yangon","Mandalay","Naypyidaw","Bagan"],
        "Cambodia": ["Phnom Penh","Siem Reap","Battambang","Sihanoukville"],
        "Laos": ["Vientiane","Luang Prabang","Pakse","Savannakhet"],
        "Fiji": ["Suva","Nadi","Lautoka","Labasa"],
        "Papua New Guinea": ["Port Moresby","Lae","Madang","Mount Hagen"],
        "New Caledonia": ["Nouméa","Mont-Dore","Dumbéa"],
        "French Polynesia": ["Papeete","Bora Bora","Moorea","Tahiti"],
        "Guam": ["Hagåtña","Dededo","Tamuning","Mangilao"],
        "Samoa": ["Apia","Vaitele","Faleula"],
        "Tonga": ["Nuku'alofa","Neiafu","Haveluloto"],
        "Maldives": ["Malé","Addu City","Fuvahmulah"],
        "Jamaica": ["Kingston","Montego Bay","Spanish Town","Ocho Rios"],
        "Barbados": ["Bridgetown","Speightstown","Oistins"],
        "Trinidad and Tobago": ["Port of Spain","San Fernando","Chaguanas","Arima"],
        "Bahamas": ["Nassau","Freeport","Marsh Harbour"],
        "Cayman Islands": ["George Town","West Bay","Bodden Town"],
        "Bermuda": ["Hamilton","St. George's","Somerset"],
        "Aruba": ["Oranjestad","San Nicolaas","Santa Cruz"],
        "Curaçao": ["Willemstad","Punda","Otrobanda"],
        "Ecuador": ["Quito","Guayaquil","Cuenca","Galápagos"],
        "Bolivia": ["La Paz","Santa Cruz","Cochabamba","Sucre"],
        "Paraguay": ["Asunción","Ciudad del Este","Encarnación"],
        "Uruguay": ["Montevideo","Punta del Este","Colonia","Salto"],
        "Venezuela": ["Caracas","Maracaibo","Valencia","Barquisimeto"],
        "Guyana": ["Georgetown","Linden","New Amsterdam"],
        "Suriname": ["Paramaribo","Lelydorp","Nieuw Nickerie"],
        "French Guiana": ["Cayenne","Saint-Laurent-du-Maroni","Kourou"]
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
        case "Australia":       return "🇦🇺"
        case "New Zealand":     return "🇳🇿"
        case "USA":             return "🇺🇸"
        case "UK":              return "🇬🇧"
        case "Canada":          return "🇨🇦"
        case "Germany":         return "🇩🇪"
        case "France":          return "🇫🇷"
        case "Japan":           return "🇯🇵"
        case "Spain":           return "🇪🇸"
        case "Italy":           return "🇮🇹"
        case "Netherlands":     return "🇳🇱"
        case "Switzerland":     return "🇨🇭"
        case "Norway":          return "🇳🇴"
        case "Sweden":          return "🇸🇪"
        case "Denmark":         return "🇩🇰"
        case "Ireland":         return "🇮🇪"
        case "South Korea":     return "🇰🇷"
        case "China":           return "🇨🇳"
        case "Singapore":       return "🇸🇬"
        case "Thailand":        return "🇹🇭"
        case "India":           return "🇮🇳"
        case "UAE":             return "🇦🇪"
        case "South Africa":    return "🇿🇦"
        case "Brazil":          return "🇧🇷"
        case "Argentina":       return "🇦🇷"
        case "Mexico":          return "🇲🇽"
        case "Austria":         return "🇦🇹"
        case "Belgium":         return "🇧🇪"
        case "Poland":          return "🇵🇱"
        case "Czech Republic":  return "🇨🇿"
        case "Portugal":        return "🇵🇹"
        case "Greece":          return "🇬🇷"
        case "Turkey":          return "🇹🇷"
        case "Russia":          return "🇷🇺"
        case "Finland":         return "🇫🇮"
        case "Iceland":         return "🇮🇸"
        case "Croatia":         return "🇭🇷"
        case "Hungary":         return "🇭🇺"
        case "Romania":         return "🇷🇴"
        case "Israel":          return "🇮🇱"
        case "Egypt":           return "🇪🇬"
        case "Morocco":         return "🇲🇦"
        case "Kenya":           return "🇰🇪"
        case "Nigeria":         return "🇳🇬"
        case "Vietnam":         return "🇻🇳"
        case "Indonesia":       return "🇮🇩"
        case "Malaysia":        return "🇲🇾"
        case "Philippines":     return "🇵🇭"
        case "Taiwan":          return "🇹🇼"
        case "Chile":           return "🇨🇱"
        case "Peru":            return "🇵🇪"
        case "Colombia":        return "🇨🇴"
        case "Costa Rica":      return "🇨🇷"
        case "Panama":          return "🇵🇦"
        case "Qatar":           return "🇶🇦"
        case "Saudi Arabia":    return "🇸🇦"
        case "Pakistan":            return "🇵🇰"
        case "Bangladesh":          return "🇧🇩"
        case "Sri Lanka":           return "🇱🇰"
        case "Algeria":             return "🇩🇿"
        case "Tunisia":             return "🇹🇳"
        case "Libya":               return "🇱🇾"
        case "Ethiopia":            return "🇪🇹"
        case "Tanzania":            return "🇹🇿"
        case "Uganda":              return "🇺🇬"
        case "Ghana":               return "🇬🇭"
        case "Senegal":             return "🇸🇳"
        case "Ivory Coast":         return "🇨🇮"
        case "Zimbabwe":            return "🇿🇼"
        case "Zambia":              return "🇿🇲"
        case "Botswana":            return "🇧🇼"
        case "Namibia":             return "🇳🇦"
        case "Mozambique":          return "🇲🇿"
        case "Madagascar":          return "🇲🇬"
        case "Mauritius":           return "🇲🇺"
        case "Seychelles":          return "🇸🇨"
        case "Réunion":             return "🇷🇪"
        case "Antarctica":          return "🇦🇶"
        case "Greenland":           return "🇬🇱"
        case "Svalbard":            return "🇸🇯"
        case "Faroe Islands":       return "🇫🇴"
        case "Jordan":              return "🇯🇴"
        case "Lebanon":             return "🇱🇧"
        case "Oman":                return "🇴🇲"
        case "Kuwait":              return "🇰🇼"
        case "Bahrain":             return "🇧🇭"
        case "Azerbaijan":          return "🇦🇿"
        case "Kazakhstan":          return "🇰🇿"
        case "Uzbekistan":          return "🇺🇿"
        case "Mongolia":            return "🇲🇳"
        case "Nepal":               return "🇳🇵"
        case "Bhutan":              return "🇧🇹"
        case "Myanmar":             return "🇲🇲"
        case "Cambodia":            return "🇰🇭"
        case "Laos":                return "🇱🇦"
        case "Fiji":                return "🇫🇯"
        case "Papua New Guinea":    return "🇵🇬"
        case "New Caledonia":       return "🇳🇨"
        case "French Polynesia":    return "🇵🇫"
        case "Guam":                return "🇬🇺"
        case "Samoa":               return "🇼🇸"
        case "Tonga":               return "🇹🇴"
        case "Maldives":            return "🇲🇻"
        case "Jamaica":             return "🇯🇲"
        case "Barbados":            return "🇧🇧"
        case "Trinidad and Tobago": return "🇹🇹"
        case "Bahamas":             return "🇧🇸"
        case "Cayman Islands":      return "🇰🇾"
        case "Bermuda":             return "🇧🇲"
        case "Aruba":               return "🇦🇼"
        case "Curaçao":             return "🇨🇼"
        case "Ecuador":             return "🇪🇨"
        case "Bolivia":             return "🇧🇴"
        case "Paraguay":            return "🇵🇾"
        case "Uruguay":             return "🇺🇾"
        case "Venezuela":           return "🇻🇪"
        case "Guyana":              return "🇬🇾"
        case "Suriname":            return "🇸🇷"
        case "French Guiana":       return "🇬🇫"
        default:                    return ""
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
