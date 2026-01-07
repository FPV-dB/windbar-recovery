import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    let manager = WeatherManager()
    var popover: NSPopover?
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {

        // --- Create the menu bar icon ---
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "—"

        // --- Build the popover content ---
        let view = WindBarView(onClose: { [weak self] in
            self?.popover?.performClose(nil)
        })
        .environmentObject(manager)

        let hosting = NSHostingController(rootView: view)

        let pop = NSPopover()
        pop.behavior = .transient
        pop.contentSize = NSSize(width: 260, height: 260)
        pop.contentViewController = hosting
        self.popover = pop

        // --- Menu bar icon click handler ---
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(togglePopover)

        // --- Update the menu bar title whenever wind changes ---
        manager.$windSpeedKmh
            .receive(on: RunLoop.main)
            .sink { [weak self] speed in
                guard let button = self?.statusItem?.button else { return }

                if let speed = speed {
                    button.title = "\(Int(speed)) km/h"
                } else {
                    button.title = "—"
                }
            }
            .store(in: &cancellables)

        // --- Kick off first fetch ---
        manager.refresh()
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let pop = popover, pop.isShown {
            pop.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds,
                          of: button,
                          preferredEdge: .minY)
        }
    }
}
