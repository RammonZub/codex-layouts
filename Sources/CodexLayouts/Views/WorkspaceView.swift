import SwiftUI

struct WorkspaceView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header

            if let layout = model.selectedLayout {
                VStack(spacing: 18) {
                    LayoutPreview(
                        layout: layout,
                        tasksByID: model.tasksByID,
                        selectedSlotID: model.selectedSlotID,
                        onSelectSlot: model.presentTaskPicker
                    )
                    .frame(maxWidth: 760, maxHeight: 470)

                    assignmentLegend(for: layout)
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

                Text("Click a window to assign a Codex task.")
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

    private func assignmentLegend(for layout: WorkspaceLayout) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(layout.slots.enumerated()), id: \.element.id) { index, slot in
                let task = slot.taskID.flatMap { model.tasksByID[$0] }
                Button {
                    model.presentTaskPicker(for: slot.id)
                } label: {
                    HStack(spacing: 6) {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .frame(width: 18, height: 18)
                            .background(.primary.opacity(0.09), in: Circle())
                        Text(task?.title ?? "Assign task")
                            .lineLimit(1)
                    }
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(task == nil ? Color.secondary : Color.primary)
                    .padding(.horizontal, 9)
                    .frame(minHeight: 34)
                    .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(PressScaleButtonStyle())
                .frame(maxWidth: 180)
            }
        }
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
