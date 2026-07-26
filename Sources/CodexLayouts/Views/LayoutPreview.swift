import SwiftUI

struct LayoutPreview: View {
    let layout: WorkspaceLayout
    let tasksByID: [String: CodexTask]
    let selectedSlotID: UUID?
    let onSelectSlot: (UUID) -> Void

    var body: some View {
        GeometryReader { proxy in
            let canvas = fittedCanvas(in: proxy.size)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: LayoutDesign.outerRadius)
                    .fill(.primary.opacity(0.025))
                    .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
                    .overlay {
                        RoundedRectangle(cornerRadius: LayoutDesign.outerRadius)
                            .stroke(.primary.opacity(0.07), lineWidth: 1)
                    }

                ZStack(alignment: .topLeading) {
                    ForEach(Array(layout.slots.enumerated()), id: \.element.id) { index, slot in
                        let frame = slot.frame
                        let task = slot.taskID.flatMap { tasksByID[$0] }

                        LayoutSlotView(
                            number: index + 1,
                            task: task,
                            isSelected: selectedSlotID == slot.id
                        ) {
                            onSelectSlot(slot.id)
                        }
                        .frame(
                            width: max(
                                42,
                                canvas.width * frame.width - LayoutDesign.slotGap
                            ),
                            height: max(
                                42,
                                canvas.height * frame.height - LayoutDesign.slotGap
                            )
                        )
                        .offset(
                            x: canvas.width * frame.x + LayoutDesign.slotGap / 2,
                            y: canvas.height * frame.y + LayoutDesign.slotGap / 2
                        )
                    }
                }
                .frame(width: canvas.width, height: canvas.height)
                .clipShape(RoundedRectangle(cornerRadius: LayoutDesign.canvasRadius))
                .padding(LayoutDesign.cardPadding)
            }
            .frame(
                width: canvas.width + (LayoutDesign.cardPadding * 2),
                height: canvas.height + (LayoutDesign.cardPadding * 2)
            )
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private func fittedCanvas(in size: CGSize) -> CGSize {
        let available = CGSize(
            width: max(1, size.width - (LayoutDesign.cardPadding * 2)),
            height: max(1, size.height - (LayoutDesign.cardPadding * 2))
        )
        let aspectRatio: CGFloat = 16.0 / 10.0
        if available.width / available.height > aspectRatio {
            return CGSize(width: available.height * aspectRatio, height: available.height)
        }
        return CGSize(width: available.width, height: available.width / aspectRatio)
    }
}

private struct LayoutSlotView: View {
    let number: Int
    let task: CodexTask?
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            slotContent
            .background {
                slotBackground
            }
            .clipShape(RoundedRectangle(cornerRadius: LayoutDesign.slotRadius))
            .overlay {
                selectionStroke
            }
            .shadow(
                color: .black.opacity(isHovering ? 0.12 : 0.07),
                radius: isHovering ? 8 : 4,
                y: isHovering ? 4 : 2
            )
            .contentShape(RoundedRectangle(cornerRadius: LayoutDesign.slotRadius))
        }
        .buttonStyle(PressScaleButtonStyle())
        .onHover { hovering in
            withAnimation(LayoutDesign.interactiveAnimation) {
                isHovering = hovering
            }
        }
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Choose a Codex task for this window")
    }

    private var slotContent: some View {
        VStack(spacing: 0) {
            titleBar
            taskContent
        }
    }

    private var titleBar: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(.primary.opacity(0.18))
                    .frame(width: 6, height: 6)
            }

            Spacer()

            Text("\(number)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .frame(height: 27)
        .background(.primary.opacity(0.045))
    }

    private var taskContent: some View {
        VStack(spacing: 7) {
            Image(systemName: task == nil ? "plus" : "text.bubble.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(taskIconColor)

            Text(task?.title ?? "Choose task")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(task == nil ? Color.secondary : Color.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            if let task {
                Text(task.projectName)
                    .font(.system(size: 9.5))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var slotBackground: some View {
        ZStack {
            FrostedBackdrop(
                material: .contentBackground,
                blendingMode: .withinWindow
            )
            Color.primary.opacity(isHovering ? 0.055 : 0.025)
        }
    }

    private var selectionStroke: some View {
        RoundedRectangle(cornerRadius: LayoutDesign.slotRadius)
            .stroke(
                isSelected ? Color.primary.opacity(0.56) : Color.primary.opacity(0.09),
                style: StrokeStyle(
                    lineWidth: isSelected ? 1.5 : 1,
                    dash: isSelected ? [5, 4] : []
                )
            )
    }

    private var taskIconColor: Color {
        task == nil ? Color.secondary.opacity(0.55) : Color.primary
    }

    private var accessibilityLabelText: String {
        if let task {
            return "Window \(number), \(task.title)"
        }
        return "Window \(number), unassigned"
    }
}
