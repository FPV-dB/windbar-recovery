import SwiftUI

@main
struct WindBarApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()   // No separate Settings window
        }
    }
}
