import AppKit
import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var isGranted = AccessibilityPermission.isGranted

    var body: some View {
        Form {
            Section("Window control") {
                LabeledContent("Accessibility") {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isGranted ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text(isGranted ? "Enabled" : "Not enabled")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text(
                        "Codex Layouts uses Accessibility only to read Codex window titles and set their position and size."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button(isGranted ? "Open Settings" : "Enable…") {
                        if isGranted {
                            model.openAccessibilitySettings()
                        } else {
                            model.requestAccessibility()
                        }
                    }
                }
            }

            Section("Tasks") {
                LabeledContent("Source") {
                    Text("~/.codex/state_5.sqlite")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Text("The database is opened read-only. Task content never leaves this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Keyboard") {
                LabeledContent("Show from anywhere") {
                    Text("⌃⌥L")
                        .font(.system(.body, design: .rounded))
                }
                LabeledContent("Show while active") {
                    Text("⌘⇧L")
                        .font(.system(.body, design: .rounded))
                }
                LabeledContent("Arrange selected layout") {
                    Text("⌘↩")
                        .font(.system(.body, design: .rounded))
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 390)
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in
            isGranted = AccessibilityPermission.isGranted
        }
    }
}
