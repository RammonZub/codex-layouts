import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var globalHotKeyController: GlobalHotKeyController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        globalHotKeyController = GlobalHotKeyController()
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }
}
