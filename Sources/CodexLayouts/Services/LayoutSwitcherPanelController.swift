import AppKit
import SwiftUI

@MainActor
final class LayoutSwitcherPanelController {
    private let session = LayoutSwitcherSession()
    private weak var model: AppModel?
    private var panel: NSPanel?
    private var keyMonitor: Any?

    func show(model: AppModel) {
        self.model = model

        if panel?.isVisible == true {
            session.move(by: 1)
            return
        }

        session.reset(
            layoutIDs: model.layouts.map(\.id),
            selectedID: model.selectedLayoutID
        )

        let content = LayoutSwitcherView(
            model: model,
            session: session,
            onApply: { [weak self] in self?.applySelection() }
        )
        let hostingController = NSHostingController(rootView: content)
        let panel = LayoutSwitcherPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hostingController
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow

        let width = min(
            max(360, CGFloat(model.layouts.count) * 126 + 22),
            900
        )
        panel.setContentSize(NSSize(width: width, height: 146))
        position(panel, on: model.selectedDisplay)

        self.panel = panel
        installKeyMonitor()
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func dismiss() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        panel?.close()
        panel = nil
    }

    private func applySelection() {
        guard let model, let selectedID = session.selectedID else {
            dismiss()
            return
        }
        model.selectLayout(selectedID)
        dismiss()
        model.arrange()
    }

    private func position(_ panel: NSPanel, on display: DisplayInfo?) {
        let screenFrame = display?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? .zero
        let panelFrame = panel.frame
        panel.setFrameOrigin(
            NSPoint(
                x: screenFrame.midX - panelFrame.width / 2,
                y: screenFrame.midY - panelFrame.height / 2
            )
        )
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            [weak self] event in
            guard let self, self.panel?.isVisible == true else {
                return event
            }
            switch event.keyCode {
            case 123:
                self.session.move(by: -1)
            case 124:
                self.session.move(by: 1)
            case 36:
                self.applySelection()
            case 53:
                self.dismiss()
            default:
                return event
            }
            return nil
        }
    }
}

private final class LayoutSwitcherPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }
}
