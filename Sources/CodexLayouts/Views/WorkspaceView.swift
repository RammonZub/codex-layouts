import SwiftUI

struct WorkspaceView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header

            if let layout = model.selectedLayout {
                LayoutPreview(
                    layout: layout,
                    wallpaperURL: model.selectedDisplay?.wallpaperURL,
                    tasksByID: model.tasksByID,
                    selectedSlotID: model.selectedSlotID,
                    onSelectSlot: model.selectSlot,
                    onAssignSlot: model.presentTaskPicker,
                    onPlaceSlot: model.placeWindow,
                    onRemoveSlot: { slotID in
                        withAnimation(LayoutDesign.layoutSpring) {
                            model.removeWindow(slotID)
                        }
                    },
                    onAddSlot: { gridRect in
                        withAnimation(LayoutDesign.layoutSpring) {
                            model.addWindow(at: gridRect)
                        }
                    }
                )
                .frame(maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .layoutPriority(1)
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
        .onDeleteCommand {
            guard (model.selectedLayout?.slots.count ?? 0) > 1 else { return }
            withAnimation(LayoutDesign.layoutSpring) {
                model.removeSelectedWindow()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 7) {
            if let layout = model.selectedLayout {
                LayoutTitleEditor(
                    layoutID: layout.id,
                    name: layout.name,
                    onCommit: model.renameSelectedLayout
                )

                Spacer(minLength: 12)

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
                    compactLabel(
                        "\(layout.gridSize.columns)×\(layout.gridSize.rows)",
                        systemImage: "grid"
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button {
                    withAnimation(LayoutDesign.layoutSpring) {
                        model.addWindow()
                    }
                } label: {
                    compactIcon("plus")
                }
                .buttonStyle(PressScaleButtonStyle())
                .help("Add window (⌘=)")
            }

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
                compactIcon("display")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help(model.selectedDisplay?.name ?? "Choose display")

            Button {
                model.duplicateSelectedLayout()
            } label: {
                compactIcon("square.on.square")
            }
            .buttonStyle(PressScaleButtonStyle())
            .help("Duplicate layout")
        }
        .padding(.leading, 18)
        .padding(.trailing, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents(true)
    }

    private func compactIcon(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 11.5, weight: .semibold))
            .frame(width: 32, height: 32)
            .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 9))
            .contentShape(Rectangle())
    }

    private func compactLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 9)
            .frame(height: 32)
            .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 9))
    }

    private var actionBar: some View {
        HStack(spacing: 8) {
            if !model.accessibilityGranted {
                Button {
                    model.requestAccessibility()
                } label: {
                    Label("Enable access", systemImage: "hand.raised")
                        .font(.system(size: 11.5, weight: .medium))
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if model.assignmentCount > 0 {
                Button {
                    model.openAssignedTasks()
                } label: {
                    compactIcon("arrow.up.forward.app")
                }
                .buttonStyle(PressScaleButtonStyle())
                .help("Open assigned tasks")
            }

            Button {
                model.arrange()
            } label: {
                Label("Arrange", systemImage: "rectangle.3.group.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 13)
                    .frame(height: 36)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 10))
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(model.assignmentCount == 0 || model.selectedDisplay == nil)
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.primary.opacity(0.055))
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
                Button {
                    draftName = name
                    isEditing = true
                    isFocused = true
                } label: {
                    HStack(spacing: 6) {
                        Text(name)
                            .lineLimit(1)
                        Image(systemName: "pencil")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Rename layout")
            }
        }
        .font(.system(size: 18, weight: .semibold, design: .rounded))
        .frame(maxWidth: 300, alignment: .leading)
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
