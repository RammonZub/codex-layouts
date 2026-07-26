import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var globalHotKeyController: GlobalHotKeyController?
    private let layoutSwitcherController = LayoutSwitcherPanelController()
    private weak var model: AppModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        globalHotKeyController = GlobalHotKeyController()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showLayoutSwitcher),
            name: AppActivation.showLayoutSwitcherNotification,
            object: nil
        )
    }

    func configure(model: AppModel) {
        self.model = model
    }

    @objc private func showLayoutSwitcher() {
        guard let model else {
            AppActivation.showMainWindow()
            return
        }
        layoutSwitcherController.show(model: model)
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }
}
