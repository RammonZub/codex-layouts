import SwiftUI

struct WorkspaceView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header

            if let layout = model.selectedLayout {
                VStack(spacing: 12) {
                    editorToolbar(for: layout)

                    LayoutPreview(
                        layout: layout,
                        tasksByID: model.tasksByID,
                        selectedSlotID: model.selectedSlotID,
                        onSelectSlot: model.selectSlot,
                        onAssignSlot: model.presentTaskPicker,
                        onPlaceSlot: model.placeWindow
                    )
                    .frame(maxWidth: 760, maxHeight: 430)

                    selectionBar(for: layout)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 34)
                .padding(.bottom, 22)
            } else {
                ContentUnavailableView(
                    "No layout selected",
                    systemImage: "rectangle.3.group",
                    description: Text("Create a layout to get started.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            actionBar
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                if let layout = model.selectedLayout {
                    LayoutTitleEditor(
                        layoutID: layout.id,
                        name: layout.name,
                        onCommit: { newName in
                            model.renameSelectedLayout(to: newName)
                        }
                    )
                }

                Text("Drag title bars to move. Resize from the selected window’s corner.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)

            Menu {
                ForEach(model.displays) { display in
                    Button {
                        model.chooseDisplay(display.id)
                    } label: {
                        if model.selectedDisplayID == display.id {
                            Label(display.name, systemImage: "checkmark")
                        } else {
                            Text(display.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "display")
                    Text(model.selectedDisplay?.name ?? "Choose display")
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .frame(height: LayoutDesign.desktopHitArea)
                .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button {
                model.duplicateSelectedLayout()
            } label: {
                Image(systemName: "square.on.square")
                    .frame(
                        width: LayoutDesign.desktopHitArea,
                        height: LayoutDesign.desktopHitArea
                    )
                    .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PressScaleButtonStyle())
            .help("Duplicate layout")
        }
        .padding(.leading, 32)
        .padding(.trailing, 22)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents(true)
    }

    private func editorToolbar(for layout: WorkspaceLayout) -> some View {
        HStack(spacing: 9) {
            Menu {
                ForEach(GridSize.editorPresets, id: \.self) { gridSize in
                    Button {
                        model.changeGridSize(to: gridSize)
                    } label: {
                        if layout.gridSize == gridSize {
                            Label(
                                "\(gridSize.columns) × \(gridSize.rows)",
                                systemImage: "checkmark"
                            )
                        } else {
                            Text("\(gridSize.columns) × \(gridSize.rows)")
                        }
                    }
                }
            } label: {
                Label(
                    "\(layout.gridSize.columns) × \(layout.gridSize.rows) grid",
                    systemImage: "grid"
                )
                .font(.system(size: 11.5, weight: .medium))
                .padding(.horizontal, 11)
                .frame(height: 34)
                .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button {
                model.addWindow()
            } label: {
                Label("Add window", systemImage: "plus")
                    .font(.system(size: 11.5, weight: .medium))
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer()

            Label("1×1 minimum · positions locked to grid", systemImage: "lock.fill")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 760)
    }

    @ViewBuilder
    private func selectionBar(for layout: WorkspaceLayout) -> some View {
        if let selectedSlotID = model.selectedSlotID,
           let index = layout.slots.firstIndex(where: { $0.id == selectedSlotID }) {
            let slot = layout.slots[index]
            let rect = GridLayoutEngine.gridRect(for: slot.frame, in: layout.gridSize)
            let task = slot.taskID.flatMap { model.tasksByID[$0] }

            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .frame(width: 22, height: 22)
                    .background(.primary.opacity(0.09), in: Circle())

                Button {
                    model.presentTaskPicker(for: slot.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: task == nil ? "plus" : "text.bubble.fill")
                        Text(task?.title ?? "Choose task")
                            .lineLimit(1)
                    }
                    .font(.system(size: 11.5, weight: .medium))
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(PressScaleButtonStyle())
                .frame(maxWidth: 230)

                Spacer()

                Text("\(rect.columnSpan) × \(rect.rowSpan)")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 40)

                sizeButton(
                    systemImage: "arrow.left",
                    help: "Make one column narrower",
                    disabled: rect.columnSpan <= 1
                ) {
                    model.resizeSelectedWindow(columns: -1)
                }
                sizeButton(
                    systemImage: "arrow.right",
                    help: "Make one column wider",
                    disabled: rect.columnSpan >= layout.gridSize.columns
                ) {
                    model.resizeSelectedWindow(columns: 1)
                }
                sizeButton(
                    systemImage: "arrow.up",
                    help: "Make one row shorter",
                    disabled: rect.rowSpan <= 1
                ) {
                    model.resizeSelectedWindow(rows: -1)
                }
                sizeButton(
                    systemImage: "arrow.down",
                    help: "Make one row taller",
                    disabled: rect.rowSpan >= layout.gridSize.rows
                ) {
                    model.resizeSelectedWindow(rows: 1)
                }

                Button(role: .destructive) {
                    model.removeSelectedWindow()
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 34, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressScaleButtonStyle())
                .disabled(layout.slots.count <= 1)
                .help("Remove window")
            }
            .frame(maxWidth: 760)
        }
    }

    private func sizeButton(
        systemImage: String,
        help: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 30, height: 30)
                .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(disabled)
        .help(help)
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            if !model.accessibilityGranted {
                Button {
                    model.requestAccessibility()
                } label: {
                    Label("Enable Accessibility", systemImage: "hand.raised")
                        .font(.system(size: 12, weight: .medium))
                        .frame(height: LayoutDesign.desktopHitArea)
                }
                .buttonStyle(.plain)
            } else {
                Label("Accessibility enabled", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(model.assignmentCount) assigned")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)

            Button {
                model.openAssignedTasks()
            } label: {
                Label("Open tasks", systemImage: "arrow.up.forward.app")
                    .padding(.horizontal, 13)
                    .frame(height: LayoutDesign.desktopHitArea)
                    .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(model.assignmentCount == 0)

            Button {
                model.arrange()
            } label: {
                Label("Arrange", systemImage: "rectangle.3.group.fill")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 15)
                    .frame(height: LayoutDesign.desktopHitArea)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(model.assignmentCount == 0 || model.selectedDisplay == nil)
        }
        .padding(.horizontal, 22)
        .frame(height: 66)
        .background(.regularMaterial.opacity(0.7))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.primary.opacity(0.07))
                .frame(height: 1)
        }
    }
}

private struct LayoutTitleEditor: View {
    let layoutID: UUID
    let name: String
    let onCommit: (String) -> Void

    @State private var draftName: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    init(layoutID: UUID, name: String, onCommit: @escaping (String) -> Void) {
        self.layoutID = layoutID
        self.name = name
        self.onCommit = onCommit
        _draftName = State(initialValue: name)
    }

    var body: some View {
        Group {
            if isEditing {
                TextField("Layout name", text: $draftName)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        commit()
                        isEditing = false
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            commit()
                            isEditing = false
                        }
                    }
            } else {
                HStack(spacing: 6) {
                    Text(name)
                        .lineLimit(1)

                    Button {
                        draftName = name
                        isEditing = true
                        isFocused = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(
                                width: LayoutDesign.desktopHitArea,
                                height: LayoutDesign.desktopHitArea
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .help("Rename layout")
                }
            }
        }
        .font(.system(size: 24, weight: .semibold, design: .rounded))
        .frame(maxWidth: 430, alignment: .leading)
        .onChange(of: layoutID) { _, _ in
            if !isEditing {
                draftName = name
            }
        }
        .accessibilityLabel("Layout name")
    }

    private func commit() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            draftName = name
            return
        }
        if trimmed != name {
            onCommit(trimmed)
        }
    }
}
