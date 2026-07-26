import SwiftUI

struct TaskPickerView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FrostedBackdrop(material: .hudWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Choose a Codex task")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        Text("Top-level conversations · grouped like your Codex workspace")
                            .font(.system(size: 11.5))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        model.reloadTasks()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(
                                width: LayoutDesign.desktopHitArea,
                                height: LayoutDesign.desktopHitArea
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .help("Refresh tasks")

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(
                                width: LayoutDesign.desktopHitArea,
                                height: LayoutDesign.desktopHitArea
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search task titles or projects", text: $model.taskSearch)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .frame(height: LayoutDesign.desktopHitArea)
                .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                Rectangle()
                    .fill(.primary.opacity(0.07))
                    .frame(height: 1)

                if model.tasks.isEmpty {
                    ContentUnavailableView(
                        "No Codex tasks found",
                        systemImage: "text.bubble",
                        description: Text(
                            model.repositoryMessage
                                ?? "Open a task in Codex, then refresh this list."
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if model.filteredTasks.isEmpty {
                    ContentUnavailableView.search(text: model.taskSearch)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            if !model.filteredPinnedTasks.isEmpty {
                                TaskSectionHeader(
                                    title: "Pinned",
                                    count: model.filteredPinnedTasks.count,
                                    systemImage: "pin.fill"
                                )

                                VStack(spacing: 3) {
                                    ForEach(model.filteredPinnedTasks) { task in
                                        TaskPickerRow(
                                            task: task,
                                            isPinned: true,
                                            onSelect: { model.assign(task.id) },
                                            onTogglePinned: {
                                                model.togglePinned(task.id)
                                            }
                                        )
                                    }
                                }
                            }

                            ForEach(model.filteredProjectGroups) { group in
                                VStack(alignment: .leading, spacing: 5) {
                                    TaskSectionHeader(
                                        title: group.name,
                                        count: group.tasks.count,
                                        systemImage: group.name == "Projectless"
                                            ? "tray"
                                            : "folder.fill"
                                    )
                                    .help(group.path)

                                    VStack(spacing: 3) {
                                        ForEach(group.tasks) { task in
                                            TaskPickerRow(
                                                task: task,
                                                isPinned: false,
                                                onSelect: { model.assign(task.id) },
                                                onTogglePinned: {
                                                    model.togglePinned(task.id)
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                    }
                }

                Rectangle()
                    .fill(.primary.opacity(0.07))
                    .frame(height: 1)

                HStack {
                    Button("Clear assignment") {
                        model.assign(nil)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Text("↩ select · esc close")
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 20)
                .frame(height: 52)
            }
        }
        .frame(width: 620, height: 540)
    }
}

private struct TaskSectionHeader: View {
    let title: String
    let count: Int
    let systemImage: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .lineLimit(1)

            Text("\(count)")
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .frame(height: 18)
                .background(.primary.opacity(0.05), in: Capsule())

            Spacer()
        }
        .padding(.horizontal, 9)
    }
}

private struct TaskPickerRow: View {
    let task: CodexTask
    let isPinned: Bool
    let onSelect: () -> Void
    let onTogglePinned: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            .primary.opacity(0.055),
                            in: RoundedRectangle(cornerRadius: 9)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.title)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(task.updatedAt, style: .relative)
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 10)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onTogglePinned) {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(isPinned ? Color.primary : Color.secondary)
                    .frame(
                        width: LayoutDesign.desktopHitArea,
                        height: LayoutDesign.desktopHitArea
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleButtonStyle())
            .help(isPinned ? "Unpin task" : "Pin task")
        }
        .padding(.leading, 10)
        .padding(.trailing, 3)
        .frame(minHeight: 50)
        .background(
            .primary.opacity(isHovering ? 0.07 : 0),
            in: RoundedRectangle(cornerRadius: 11)
        )
        .contentShape(RoundedRectangle(cornerRadius: 11))
        .onHover { hovering in
            withAnimation(LayoutDesign.interactiveAnimation) {
                isHovering = hovering
            }
        }
    }
}
