import SwiftUI

@MainActor
@Observable
final class LayoutSwitcherSession {
    private(set) var selection = LayoutSwitcherSelection(
        layoutIDs: [],
        selectedID: nil
    )

    var selectedID: UUID? {
        selection.selectedID
    }

    func reset(layoutIDs: [UUID], selectedID: UUID?) {
        selection = LayoutSwitcherSelection(
            layoutIDs: layoutIDs,
            selectedID: selectedID
        )
    }

    func select(_ id: UUID) {
        selection = LayoutSwitcherSelection(
            layoutIDs: selection.layoutIDs,
            selectedID: id
        )
    }

    func move(by offset: Int) {
        selection.move(by: offset)
    }
}

struct LayoutSwitcherView: View {
    @Bindable var model: AppModel
    @Bindable var session: LayoutSwitcherSession
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 12, weight: .semibold))

                Text("Choose a layout")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Text("⌘⇧L")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(model.layouts) { layout in
                        layoutButton(layout)
                    }
                }
                .padding(1)
            }
            .scrollIndicators(.hidden)
        }
        .padding(14)
        .background {
            ZStack {
                FrostedBackdrop(material: .hudWindow)
                Color.white.opacity(0.045)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.24), radius: 30, y: 14)
    }

    private func layoutButton(_ layout: WorkspaceLayout) -> some View {
        let isSelected = session.selectedID == layout.id

        return Button {
            session.select(layout.id)
            onApply()
        } label: {
            VStack(spacing: 7) {
                LayoutGlyph(layout: layout)
                    .frame(width: 92, height: 58)

                Text(layout.name)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(width: 102)
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isSelected
                            ? Color.accentColor.opacity(0.2)
                            : Color.white.opacity(0.055)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected
                            ? Color.accentColor.opacity(0.9)
                            : Color.white.opacity(0.24),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            if isHovering {
                session.select(layout.id)
            }
        }
    }
}
