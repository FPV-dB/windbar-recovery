import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    let manager = WeatherManager()
    let settings = AppSettings()
    var mainWindow: NSWindow?
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {

        // --- Create the menu bar icon ---
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "—"

        // --- Create menu ---
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open WindBar", action: #selector(openMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let iconStyleItem = NSMenuItem(title: "Icon Style", action: nil, keyEquivalent: "")
        let iconSubmenu = NSMenu()
        iconSubmenu.addItem(NSMenuItem(title: "Wind + Arrow", action: #selector(setIconStyleWindAndArrow), keyEquivalent: ""))
        iconSubmenu.addItem(NSMenuItem(title: "Arrow Only", action: #selector(setIconStyleArrowOnly), keyEquivalent: ""))
        iconSubmenu.addItem(NSMenuItem(title: "Wind Only", action: #selector(setIconStyleWindOnly), keyEquivalent: ""))
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

    private func updateMenuBarDisplay() {
        guard let button = statusItem?.button else { return }

        let speed = manager.windSpeedKmh
        let gust = manager.windGustKmh
        let unit = manager.windUnit.displayName
        let direction = manager.windDirectionDeg

        var title = ""

        switch settings.iconStyle {
        case .windAndArrow, .arrowOnly:
            // Add wind direction arrow - arrow points FROM where wind is coming
            title += windArrow(for: direction) + " "
        case .windOnly:
            break
        }

        if let s = speed {
            title += "\(Int(s)) \(unit)"
            if let g = gust {
                title += " — Gusts to \(Int(g)) \(unit)"
            }
        } else {
            title += "—"
        }

        if settings.iconStyle == .arrowOnly {
            title = windArrow(for: direction) + " "
        }

        button.title = title
    }

    private func windArrow(for degrees: Double?) -> String {
        guard let deg = degrees else { return "↓" }

        // Wind direction arrows - arrow points FROM where wind is coming
        // 0° = North wind (wind FROM north, arrow points down ↓)
        // 90° = East wind (wind FROM east, arrow points left ←)
        // 180° = South wind (wind FROM south, arrow points up ↑)
        // 270° = West wind (wind FROM west, arrow points right →)

        let normalized = Int(deg) % 360

        switch normalized {
        case 337...360, 0..<23:   return "↓"  // N
        case 23..<68:             return "↙"  // NE
        case 68..<113:            return "←"  // E
        case 113..<158:           return "↖"  // SE
        case 158..<203:           return "↑"  // S
        case 203..<248:           return "↗"  // SW
        case 248..<293:           return "→"  // W
        case 293..<338:           return "↘"  // NW
        default:                  return "↓"
        }
    }
}
