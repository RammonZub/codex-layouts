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
    var pinnedTaskIDs: Set<String>

    private let layoutStore: LayoutStore
    private let taskRepository: CodexTaskRepository
    private let arranger: WindowArranger
    private let defaults: UserDefaults

    private static let pinnedTaskIDsKey = "pinnedTaskIDs"

    init(
        layoutStore: LayoutStore = LayoutStore(),
        taskRepository: CodexTaskRepository = CodexTaskRepository(),
        arranger: WindowArranger = WindowArranger(),
        defaults: UserDefaults = .standard
    ) {
        self.layoutStore = layoutStore
        self.taskRepository = taskRepository
        self.arranger = arranger
        self.defaults = defaults
        pinnedTaskIDs = Set(defaults.stringArray(forKey: Self.pinnedTaskIDsKey) ?? [])
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

    var filteredPinnedTasks: [CodexTask] {
        filteredTasks.filter { pinnedTaskIDs.contains($0.id) }
    }

    var filteredProjectGroups: [CodexProjectGroup] {
        let unpinned = filteredTasks.filter { !pinnedTaskIDs.contains($0.id) }
        return Dictionary(grouping: unpinned, by: \.projectID)
            .map { projectID, tasks in
                CodexProjectGroup(
                    id: projectID,
                    name: tasks[0].projectName,
                    path: tasks[0].projectPath,
                    tasks: tasks.sorted { $0.updatedAt > $1.updatedAt }
                )
            }
            .sorted {
                if $0.mostRecentUpdate != $1.mostRecentUpdate {
                    return $0.mostRecentUpdate > $1.mostRecentUpdate
                }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
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
        selectedSlotID = selectedLayout?.slots.first?.id
    }

    func selectSlot(_ id: UUID) {
        selectedSlotID = id
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

    func togglePinned(_ taskID: String) {
        if pinnedTaskIDs.contains(taskID) {
            pinnedTaskIDs.remove(taskID)
        } else {
            pinnedTaskIDs.insert(taskID)
        }
        defaults.set(pinnedTaskIDs.sorted(), forKey: Self.pinnedTaskIDsKey)
    }

    func createLayout() {
        let grid = GridSize.canvasDefault
        let layout = WorkspaceLayout(
            name: uniqueName("Untitled Layout"),
            slots: [
                LayoutSlot(
                    frame: GridLayoutEngine.normalizedRect(
                        for: GridRect(
                            column: 0,
                            row: 0,
                            columnSpan: 1,
                            rowSpan: 1
                        ),
                        in: grid
                    )
                )
            ],
            gridSize: grid,
            isStarter: false
        )
        layouts.append(layout)
        selectedLayoutID = layout.id
        selectedSlotID = layout.slots.first?.id
        persistLayouts()
    }

    func duplicateSelectedLayout() {
        guard let source = selectedLayout else { return }
        let copy = WorkspaceLayout(
            name: uniqueName("\(source.name) Copy"),
            slots: source.slots.map { LayoutSlot(frame: $0.frame, taskID: $0.taskID) },
            gridSize: source.gridSize,
            isStarter: false
        )
        layouts.append(copy)
        selectedLayoutID = copy.id
        selectedSlotID = copy.slots.first?.id
        persistLayouts()
    }

    func addWindow() {
        guard let layoutIndex = selectedLayoutIndex else { return }
        let layout = layouts[layoutIndex]
        guard let slot = GridLayoutEngine.addingUnitSlot(
            to: layout.slots,
            in: layout.gridSize
        ) else {
            showStatus("This grid is full. Expand the grid or resize another window first.")
            return
        }
        layouts[layoutIndex].slots.append(slot)
        layouts[layoutIndex].isStarter = false
        selectedSlotID = slot.id
        persistLayouts()
    }

    func removeSelectedWindow() {
        guard let selectedSlotID else { return }
        removeWindow(selectedSlotID)
    }

    func removeWindow(_ slotID: UUID) {
        guard let layoutIndex = selectedLayoutIndex,
              layouts[layoutIndex].slots.count > 1,
              let slotIndex = layouts[layoutIndex].slots.firstIndex(where: {
                  $0.id == slotID
              }) else {
            return
        }
        layouts[layoutIndex].slots.remove(at: slotIndex)
        layouts[layoutIndex].isStarter = false
        self.selectedSlotID = layouts[layoutIndex].slots[
            min(slotIndex, layouts[layoutIndex].slots.count - 1)
        ].id
        persistLayouts()
    }

    func placeWindow(_ slotID: UUID, at gridRect: GridRect) {
        guard let layoutIndex = selectedLayoutIndex else { return }
        let layout = layouts[layoutIndex]
        guard let slots = GridLayoutEngine.reflowing(
            layout.slots,
            moving: slotID,
            to: gridRect,
            in: layout.gridSize
        ) else {
            showStatus("That size does not fit. Free more grid cells and try again.")
            return
        }
        guard slots != layout.slots else {
            selectedSlotID = slotID
            return
        }
        layouts[layoutIndex].slots = slots
        layouts[layoutIndex].isStarter = false
        selectedSlotID = slotID
        persistLayouts()
    }

    func resizeSelectedWindow(columns: Int = 0, rows: Int = 0) {
        guard let layout = selectedLayout,
              let selectedSlotID,
              let slot = layout.slots.first(where: { $0.id == selectedSlotID }) else {
            return
        }
        var gridRect = GridLayoutEngine.gridRect(for: slot.frame, in: layout.gridSize)
        gridRect.columnSpan = min(
            max(1, gridRect.columnSpan + columns),
            layout.gridSize.columns - gridRect.column
        )
        gridRect.rowSpan = min(
            max(1, gridRect.rowSpan + rows),
            layout.gridSize.rows - gridRect.row
        )
        placeWindow(selectedSlotID, at: gridRect)
    }

    func changeGridSize(to gridSize: GridSize) {
        guard let layoutIndex = selectedLayoutIndex else { return }
        let layout = layouts[layoutIndex]
        guard gridSize != layout.gridSize else { return }
        guard let slots = GridLayoutEngine.regridding(
            layout.slots,
            from: layout.gridSize,
            to: gridSize
        ) else {
            showStatus("The windows do not fit in a \(gridSize.columns) × \(gridSize.rows) grid.")
            return
        }
        layouts[layoutIndex].slots = slots
        layouts[layoutIndex].gridSize = gridSize
        layouts[layoutIndex].isStarter = false
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
        selectedSlotID = selectedLayout?.slots.first?.id
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
                ? "No recent top-level Codex tasks were found."
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
        selectedSlotID = selectedLayout?.slots.first?.id

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
