import AppKit
import SwiftUI
import BrewNotifierCore

@main
struct BrewNotifierApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var checker = UpdateChecker()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon — menu bar only app
        NSApp.setActivationPolicy(.accessory)

        statusBarController = StatusBarController(checker: checker)
        checker.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        checker.stop()
    }
}
