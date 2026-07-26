import AppKit

@MainActor
enum AppActivation {
    static func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows
            .first(where: { $0.canBecomeKey && $0.title != "Settings" })?
            .makeKeyAndOrderFront(nil)
    }
}
