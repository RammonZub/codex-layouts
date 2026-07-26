import AppKit
import Foundation

@MainActor
enum CodexURLLauncher {
    static func open(_ task: CodexTask) {
        guard let url = task.deepLink else { return }
        NSWorkspace.shared.open(url)
    }
}
