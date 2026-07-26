import SwiftUI

struct SidebarView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 28, height: 28)
                    .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))

                Text("Layouts")
                    .font(.system(size: 13, weight: .semibold))

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
            .padding(.leading, 14)
            .padding(.trailing, 7)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .gesture(WindowDragGesture())
            .allowsWindowActivationEvents(true)

            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(model.layouts) { layout in
                        LayoutSidebarRow(
                            layout: layout,
                            isSelected: layout.id == model.selectedLayoutID
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
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }

            Spacer(minLength: 0)
        }
        .background(.thinMaterial.opacity(0.44))
    }
}

private struct LayoutSidebarRow: View {
    let layout: WorkspaceLayout
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                MiniLayoutGlyph(layout: layout)
                    .frame(width: 32, height: 24)

                Text(layout.name)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 42)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.primary.opacity(0.085) : Color.clear)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
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
