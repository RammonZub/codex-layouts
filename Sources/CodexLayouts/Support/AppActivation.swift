import AppKit

@MainActor
enum AppActivation {
    static let showLayoutSwitcherNotification = Notification.Name(
        "CodexLayouts.showLayoutSwitcher"
    )

    static func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows
            .first(where: { $0.canBecomeKey && $0.title != "Settings" })?
            .makeKeyAndOrderFront(nil)
    }

    static func showLayoutSwitcher() {
        NotificationCenter.default.post(
            name: showLayoutSwitcherNotification,
            object: nil
        )
    }
}
