import SwiftUI

struct SidebarView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 30, height: 30)
                    .background(.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Codex Layouts")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Workspace presets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)
            .contentShape(Rectangle())
            .gesture(WindowDragGesture())
            .allowsWindowActivationEvents(true)

            HStack {
                Text("LAYOUTS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .tracking(0.7)

                Spacer()

                Button {
                    model.createLayout()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(
                            width: LayoutDesign.desktopHitArea,
                            height: LayoutDesign.desktopHitArea
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressScaleButtonStyle())
                .help("New layout")
            }
            .padding(.leading, 18)
            .padding(.trailing, 8)

            ScrollView {
                LazyVStack(spacing: 5) {
                    ForEach(model.layouts) { layout in
                        LayoutSidebarRow(
                            layout: layout,
                            isSelected: layout.id == model.selectedLayoutID,
                            taskCount: layout.slots.compactMap(\.taskID).count
                        ) {
                            withAnimation(LayoutDesign.stateAnimation) {
                                model.selectLayout(layout.id)
                            }
                        }
                        .contextMenu {
                            Button("Duplicate") {
                                model.selectLayout(layout.id)
                                model.duplicateSelectedLayout()
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                model.selectLayout(layout.id)
                                model.deleteSelectedLayout()
                            }
                            .disabled(model.layouts.count <= 1)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Circle()
                    .fill(model.accessibilityGranted ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(model.accessibilityGranted ? "Ready to arrange" : "Permission needed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(14)
            .background(.primary.opacity(0.035))
        }
        .background(.thinMaterial.opacity(0.52))
    }
}

private struct LayoutSidebarRow: View {
    let layout: WorkspaceLayout
    let isSelected: Bool
    let taskCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                MiniLayoutGlyph(layout: layout)
                    .frame(width: 38, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(layout.name)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(layout.slots.count) windows · \(taskCount) assigned")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primary.opacity(0.10) : Color.clear)
                    .shadow(
                        color: isSelected ? Color.black.opacity(0.06) : Color.clear,
                        radius: 3,
                        y: 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct MiniLayoutGlyph: View {
    let layout: WorkspaceLayout

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.primary.opacity(0.035))

                ForEach(layout.slots) { slot in
                    let frame = slot.frame
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(.primary.opacity(slot.taskID == nil ? 0.16 : 0.32))
                        .frame(
                            width: max(2, proxy.size.width * frame.width - 1.5),
                            height: max(2, proxy.size.height * frame.height - 1.5)
                        )
                        .offset(
                            x: proxy.size.width * frame.x + 0.75,
                            y: proxy.size.height * frame.y + 0.75
                        )
                }
            }
        }
    }
}
