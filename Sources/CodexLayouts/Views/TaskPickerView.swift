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
                        Text("Recent local tasks · nothing is uploaded")
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
                    TextField("Search tasks or projects", text: $model.taskSearch)
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
                        LazyVStack(spacing: 4) {
                            ForEach(model.filteredTasks) { task in
                                TaskPickerRow(task: task) {
                                    model.assign(task.id)
                                }
                            }
                        }
                        .padding(10)
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

private struct TaskPickerRow: View {
    let task: CodexTask
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(task.projectName)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                Text(task.updatedAt, style: .relative)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 50)
            .background(
                .primary.opacity(isHovering ? 0.07 : 0),
                in: RoundedRectangle(cornerRadius: 11)
            )
            .contentShape(RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(PressScaleButtonStyle())
        .onHover { hovering in
            withAnimation(LayoutDesign.interactiveAnimation) {
                isHovering = hovering
            }
        }
    }
}
