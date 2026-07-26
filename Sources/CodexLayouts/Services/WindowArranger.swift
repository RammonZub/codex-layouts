@preconcurrency import ApplicationServices
import AppKit
import Foundation

struct WindowArranger {
    enum ArrangeError: LocalizedError {
        case accessibilityPermissionRequired
        case codexIsNotRunning
        case windowsUnavailable

        var errorDescription: String? {
            switch self {
            case .accessibilityPermissionRequired:
                "Accessibility permission is required to move Codex windows."
            case .codexIsNotRunning:
                "Codex is not running. Open the assigned tasks, then try again."
            case .windowsUnavailable:
                "Codex windows could not be inspected."
            }
        }
    }

    private static let bundleIdentifiers = [
        "com.openai.codex",
        "com.openai.chatgpt"
    ]

    func arrange(
        layout: WorkspaceLayout,
        tasksByID: [String: CodexTask],
        display: DisplayInfo,
        outerPadding: CGFloat = 6,
        gap: CGFloat = 8
    ) throws -> ArrangementResult {
        guard AccessibilityPermission.isGranted else {
            throw ArrangeError.accessibilityPermissionRequired
        }

        guard let application = NSWorkspace.shared.runningApplications.first(where: {
            guard let bundleIdentifier = $0.bundleIdentifier else { return false }
            return Self.bundleIdentifiers.contains(bundleIdentifier)
                || $0.localizedName == "ChatGPT"
                || $0.localizedName == "Codex"
        }) else {
            throw ArrangeError.codexIsNotRunning
        }

        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        var rawWindows: CFTypeRef?
        let copyResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &rawWindows
        )
        guard copyResult == .success,
              let windows = rawWindows as? [AXUIElement] else {
            throw ArrangeError.windowsUnavailable
        }

        let assignments = layout.slots.compactMap { slot -> (LayoutSlot, CodexTask)? in
            guard let taskID = slot.taskID, let task = tasksByID[taskID] else {
                return nil
            }
            return (slot, task)
        }

        var availableWindows = windows
        var arrangedCount = 0
        var missingTitles: [String] = []

        for (slot, task) in assignments {
            guard let matchIndex = bestMatchIndex(for: task.title, in: availableWindows) else {
                missingTitles.append(task.title)
                continue
            }

            let window = availableWindows.remove(at: matchIndex)
            let appKitFrame = slot.frame.appKitFrame(
                in: display.visibleFrame,
                outerPadding: outerPadding,
                gap: gap
            )
            setFrame(appKitFrame, on: window)
            arrangedCount += 1
        }

        return ArrangementResult(
            arrangedCount: arrangedCount,
            requestedCount: assignments.count,
            missingTaskTitles: missingTitles
        )
    }

    private func bestMatchIndex(for taskTitle: String, in windows: [AXUIElement]) -> Int? {
        let indexedTitles: [(index: Int, title: String)] = windows.enumerated().compactMap {
            index, window -> (index: Int, title: String)? in
            guard let title = title(of: window), !title.isEmpty else { return nil }
            return (index, title)
        }
        guard let match = WindowTitleMatcher.bestMatchIndex(
            for: taskTitle,
            in: indexedTitles.map { $0.title }
        ) else {
            return nil
        }
        return indexedTitles[match].index
    }

    private func title(of window: AXUIElement) -> String? {
        var rawTitle: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            window,
            kAXTitleAttribute as CFString,
            &rawTitle
        ) == .success else {
            return nil
        }
        return rawTitle as? String
    }

    private func setFrame(_ appKitFrame: CGRect, on window: AXUIElement) {
        var position = CGPoint(
            x: appKitFrame.minX,
            y: primaryDisplayTop - appKitFrame.maxY
        )
        var size = appKitFrame.size

        if let positionValue = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(
                window,
                kAXPositionAttribute as CFString,
                positionValue
            )
        }
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(
                window,
                kAXSizeAttribute as CFString,
                sizeValue
            )
        }
    }

    private var primaryDisplayTop: CGFloat {
        NSScreen.screens.first?.frame.maxY ?? 0
    }
}
