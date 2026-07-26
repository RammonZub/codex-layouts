import SwiftUI

@main
struct CodexLayoutsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup("Codex Layouts", id: "main") {
            ContentView(model: model)
                .containerBackground(.thinMaterial, for: .window)
                .task {
                    appDelegate.configure(model: model)
                }
        }
        .defaultSize(width: 1_280, height: 820)
        .defaultLaunchBehavior(.presented)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandMenu("Workspace") {
                Button("Show Layout Switcher") {
                    AppActivation.showLayoutSwitcher()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])

                Divider()

                Button("New Layout") {
                    model.createLayout()
                }
                .keyboardShortcut("n", modifiers: [.command, .option])

                Button("Add Window") {
                    withAnimation(LayoutDesign.layoutSpring) {
                        model.addWindow()
                    }
                }
                .keyboardShortcut("=", modifiers: [.command])

                Button("Remove Selected Window", role: .destructive) {
                    withAnimation(LayoutDesign.layoutSpring) {
                        model.removeSelectedWindow()
                    }
                }
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled((model.selectedLayout?.slots.count ?? 0) <= 1)

                Button("Open Assigned Tasks") {
                    model.openAssignedTasks()
                }
                .disabled(model.assignmentCount == 0)

                Button("Arrange Selected Layout") {
                    model.arrange()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(model.assignmentCount == 0)
            }
        }

        MenuBarExtra("Codex Layouts", systemImage: "rectangle.3.group") {
            Button("Show Layouts") {
                AppActivation.showMainWindow()
            }
            Button("Arrange \(model.selectedLayout?.name ?? "Layout")") {
                model.arrange()
            }
            .disabled(model.assignmentCount == 0)
            Divider()
            SettingsLink()
            Button("Quit Codex Layouts") {
                NSApplication.shared.terminate(nil)
            }
        }

        Settings {
            SettingsView(model: model)
        }
    }
}
