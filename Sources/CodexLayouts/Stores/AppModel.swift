import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var layouts: [WorkspaceLayout] = []
    var selectedLayoutID: UUID?
    var tasks: [CodexTask] = []
    var displays: [DisplayInfo] = []
    var selectedDisplayID: UInt32?
    var selectedSlotID: UUID?
    var isShowingTaskPicker = false
    var taskSearch = ""
    var statusMessage: String?
    var isShowingStatus = false
    var repositoryMessage: String?

    private let layoutStore: LayoutStore
    private let taskRepository: CodexTaskRepository
    private let arranger: WindowArranger

    init(
        layoutStore: LayoutStore = LayoutStore(),
        taskRepository: CodexTaskRepository = CodexTaskRepository(),
        arranger: WindowArranger = WindowArranger()
    ) {
        self.layoutStore = layoutStore
        self.taskRepository = taskRepository
        self.arranger = arranger
        load()
    }

    var selectedLayout: WorkspaceLayout? {
        guard let selectedLayoutID else { return nil }
        return layouts.first(where: { $0.id == selectedLayoutID })
    }

    var selectedDisplay: DisplayInfo? {
        guard let selectedDisplayID else { return nil }
        return displays.first(where: { $0.id == selectedDisplayID })
    }

    var tasksByID: [String: CodexTask] {
        Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
    }

    var filteredTasks: [CodexTask] {
        guard !taskSearch.isEmpty else { return tasks }
        return tasks.filter {
            $0.title.localizedCaseInsensitiveContains(taskSearch)
                || $0.projectName.localizedCaseInsensitiveContains(taskSearch)
                || $0.projectPath.localizedCaseInsensitiveContains(taskSearch)
        }
    }

    var assignmentCount: Int {
        selectedLayout?.slots.compactMap(\.taskID).count ?? 0
    }

    var accessibilityGranted: Bool {
        AccessibilityPermission.isGranted
    }

    func selectLayout(_ id: UUID) {
        selectedLayoutID = id
    }

    func presentTaskPicker(for slotID: UUID) {
        selectedSlotID = slotID
        taskSearch = ""
        isShowingTaskPicker = true
    }

    func assign(_ taskID: String?) {
        guard let layoutIndex = selectedLayoutIndex,
              let selectedSlotID,
              let slotIndex = layouts[layoutIndex].slots.firstIndex(where: {
                  $0.id == selectedSlotID
              }) else {
            return
        }
        layouts[layoutIndex].slots[slotIndex].taskID = taskID
        isShowingTaskPicker = false
        persistLayouts()
    }

    func createLayout() {
        let source = selectedLayout ?? WorkspaceLayout.starters[0]
        var copy = source
        copy = WorkspaceLayout(
            name: uniqueName("Untitled Layout"),
            slots: copy.slots.map { LayoutSlot(frame: $0.frame) },
            isStarter: false
        )
        layouts.append(copy)
        selectedLayoutID = copy.id
        persistLayouts()
    }

    func duplicateSelectedLayout() {
        guard let source = selectedLayout else { return }
        let copy = WorkspaceLayout(
            name: uniqueName("\(source.name) Copy"),
            slots: source.slots.map { LayoutSlot(frame: $0.frame, taskID: $0.taskID) },
            isStarter: false
        )
        layouts.append(copy)
        selectedLayoutID = copy.id
        persistLayouts()
    }

    func renameSelectedLayout(to name: String) {
        guard let index = selectedLayoutIndex else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        layouts[index].name = trimmed
        layouts[index].isStarter = false
        persistLayouts()
    }

    func deleteSelectedLayout() {
        guard layouts.count > 1, let index = selectedLayoutIndex else { return }
        layouts.remove(at: index)
        selectedLayoutID = layouts[min(index, layouts.count - 1)].id
        persistLayouts()
    }

    func chooseDisplay(_ id: UInt32) {
        selectedDisplayID = id
        UserDefaults.standard.set(Int(id), forKey: "selectedDisplayID")
    }

    func reloadTasks() {
        do {
            tasks = try taskRepository.loadRecentTasks()
            repositoryMessage = tasks.isEmpty
                ? "No recent Codex tasks were found."
                : nil
        } catch {
            tasks = []
            repositoryMessage = error.localizedDescription
        }
    }

    func openAssignedTasks() {
        guard let layout = selectedLayout else { return }
        let assignedTasks = layout.slots.compactMap { slot in
            slot.taskID.flatMap { tasksByID[$0] }
        }
        assignedTasks.forEach(CodexURLLauncher.open)
    }

    func arrange() {
        guard let layout = selectedLayout, let display = selectedDisplay else {
            showStatus("Choose a layout and display first.")
            return
        }
        do {
            let result = try arranger.arrange(
                layout: layout,
                tasksByID: tasksByID,
                display: display
            )
            showStatus(result.message)
        } catch WindowArranger.ArrangeError.accessibilityPermissionRequired {
            AccessibilityPermission.request()
            showStatus(
                "Allow Codex Layouts in System Settings → Privacy & Security → Accessibility, then arrange again."
            )
        } catch {
            showStatus(error.localizedDescription)
        }
    }

    func requestAccessibility() {
        AccessibilityPermission.request()
    }

    func openAccessibilitySettings() {
        AccessibilityPermission.openSystemSettings()
    }

    private var selectedLayoutIndex: Int? {
        guard let selectedLayoutID else { return nil }
        return layouts.firstIndex(where: { $0.id == selectedLayoutID })
    }

    private func load() {
        do {
            layouts = try layoutStore.load()
            if layouts.isEmpty {
                layouts = WorkspaceLayout.starters
            }
        } catch {
            layouts = WorkspaceLayout.starters
            repositoryMessage = "Saved layouts could not be read. Starter layouts were restored."
        }
        selectedLayoutID = layouts.first?.id

        displays = DisplayInfo.connected
        let storedDisplayID = UInt32(
            UserDefaults.standard.integer(forKey: "selectedDisplayID")
        )
        selectedDisplayID = displays.first(where: { $0.id == storedDisplayID })?.id
            ?? displays.first(where: { $0.name.localizedCaseInsensitiveContains("LG") })?.id
            ?? displays.first?.id

        reloadTasks()
    }

    private func persistLayouts() {
        do {
            try layoutStore.save(layouts)
        } catch {
            showStatus("The layout could not be saved: \(error.localizedDescription)")
        }
    }

    private func uniqueName(_ base: String) -> String {
        guard layouts.contains(where: { $0.name == base }) else { return base }
        var index = 2
        while layouts.contains(where: { $0.name == "\(base) \(index)" }) {
            index += 1
        }
        return "\(base) \(index)"
    }

    private func showStatus(_ message: String) {
        statusMessage = message
        isShowingStatus = true
    }
}
