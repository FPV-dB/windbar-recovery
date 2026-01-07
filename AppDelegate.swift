//
//  AppDelegate.swift
//  WindBar
//
//  Copyright © 2026 db. All rights reserved.
//  Licensed under the MIT License.
//  Please attribute me if you use my work.
//

import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    let manager = WeatherManager()
    let settings = AppSettings()
    var mainWindow: NSWindow?
    var cancellables = Set<AnyCancellable>()
    var isAlertActive = false

    func applicationDidFinishLaunching(_ notification: Notification) {

        // --- Create the menu bar icon ---
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "—"

        // --- Create menu ---
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open WindBar", action: #selector(openMainWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(NSMenuItem.separator())

        let iconStyleItem = NSMenuItem(title: "Icon Style", action: nil, keyEquivalent: "")
        let iconSubmenu = NSMenu()

        let windAndArrowItem = NSMenuItem(title: "Wind + Arrow", action: #selector(setIconStyleWindAndArrow), keyEquivalent: "")
        windAndArrowItem.target = self
        iconSubmenu.addItem(windAndArrowItem)

        let arrowOnlyItem = NSMenuItem(title: "Arrow Only", action: #selector(setIconStyleArrowOnly), keyEquivalent: "")
        arrowOnlyItem.target = self
        iconSubmenu.addItem(arrowOnlyItem)

        let windOnlyItem = NSMenuItem(title: "Wind Only", action: #selector(setIconStyleWindOnly), keyEquivalent: "")
        windOnlyItem.target = self
        iconSubmenu.addItem(windOnlyItem)

        let compactItem = NSMenuItem(title: "Compact", action: #selector(setIconStyleCompact), keyEquivalent: "")
        compactItem.target = self
        iconSubmenu.addItem(compactItem)

        iconStyleItem.submenu = iconSubmenu
        menu.addItem(iconStyleItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit WindBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu

        // --- Update the menu bar title whenever wind changes ---
        manager.$windSpeedKmh
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenuBarDisplay()
            }
            .store(in: &cancellables)

        manager.$windGustKmh
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenuBarDisplay()
            }
            .store(in: &cancellables)

        manager.$windDirectionDeg
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenuBarDisplay()
            }
            .store(in: &cancellables)

        manager.$windDirectionCompass
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenuBarDisplay()
            }
            .store(in: &cancellables)

        // --- Kick off first fetch ---
        manager.refresh()
    }

    @objc func openMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = MainWindBarView()
            .environmentObject(manager)
            .environmentObject(settings)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: settings.windowWidth.width, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WindBar"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false

        self.mainWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func setIconStyleWindAndArrow() {
        settings.iconStyle = .windAndArrow
        updateMenuBarDisplay()
    }

    @objc func setIconStyleArrowOnly() {
        settings.iconStyle = .arrowOnly
        updateMenuBarDisplay()
    }

    @objc func setIconStyleWindOnly() {
        settings.iconStyle = .windOnly
        updateMenuBarDisplay()
    }

    @objc func setIconStyleCompact() {
        settings.iconStyle = .compact
        updateMenuBarDisplay()
    }

    private func updateMenuBarDisplay() {
        guard let button = statusItem?.button else { return }

        let speed = manager.windSpeedKmh
        let gust = manager.windGustKmh
        let unit = manager.windUnit.displayName
        let direction = manager.windDirectionDeg
        let compass = manager.windDirectionCompass

        var title = ""

        // Check if wind exceeds custom limit and alerts are enabled
        if settings.enableWindAlerts, let s = speed {
            // Convert speed to km/h for comparison
            let speedKmh = s
            if speedKmh > settings.customDroneWindLimit {
                title += "🔔 "
                // Play alert sound when wind first exceeds limit
                if !isAlertActive {
                    isAlertActive = true
                    settings.playAlertSound()
                }
            } else {
                // Reset alert when wind drops below limit
                isAlertActive = false
            }
        }

        // Compact mode: abbreviated format without arrows or intercardinals
        if settings.iconStyle == .compact {
            let unitAbbrev = abbreviatedUnit(unit)
            if let s = speed {
                title += "💨\(Int(s))\(unitAbbrev)"
                if let g = gust {
                    title += " G\(Int(g))\(unitAbbrev)"
                }
            } else {
                title += "—"
            }
            button.title = limitMenuBarText(title)
            return
        }

        switch settings.iconStyle {
        case .windAndArrow, .arrowOnly:
            // Add wind direction arrow - arrow points FROM where wind is coming
            title += windArrow(for: direction) + " "
        case .windOnly, .compact:
            break
        }

        if let s = speed {
            title += "\(Int(s)) \(unit)"
            if let c = compass {
                title += " \(c)"
            }
            if let g = gust {
                title += " — Gusts "
                title += windArrow(for: direction) + " "
                title += "\(Int(g)) \(unit)"
                if let c = compass {
                    title += " \(c)"
                }
            }
        } else {
            title += "—"
        }

        if settings.iconStyle == .arrowOnly {
            title = windArrow(for: direction) + " "
        }

        button.title = limitMenuBarText(title)
    }

    private func limitMenuBarText(_ text: String) -> String {
        // Limit menu bar text to reasonable length (about 50 characters)
        let maxLength = 50
        if text.count > maxLength {
            let index = text.index(text.startIndex, offsetBy: maxLength - 1)
            return String(text[..<index]) + "…"
        }
        return text
    }

    private func abbreviatedUnit(_ unit: String) -> String {
        switch unit {
        case "km/h": return "k"
        case "mph": return "M"
        case "m/s": return "m"
        case "knots": return "K"
        default: return unit
        }
    }

    private func windArrow(for degrees: Double?) -> String {
        guard let deg = degrees else { return "↑" }

        // Wind direction: arrow points in the direction the wind is FROM
        // Meteorological convention: 0° = North wind (from North)
        // 0° = North wind → arrow points North ↑
        // 90° = East wind → arrow points East →
        // 180° = South wind → arrow points South ↓
        // 270° = West wind → arrow points West ←

        let normalized = Int(deg) % 360

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
