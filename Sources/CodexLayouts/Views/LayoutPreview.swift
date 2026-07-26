import SwiftUI

struct LayoutPreview: View {
    let layout: WorkspaceLayout
    let tasksByID: [String: CodexTask]
    let selectedSlotID: UUID?
    let onSelectSlot: (UUID) -> Void
    let onAssignSlot: (UUID) -> Void
    let onPlaceSlot: (UUID, GridRect) -> Void

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

                ZStack {
                    LayoutGridBackground(gridSize: layout.gridSize)

                    ForEach(Array(layout.slots.enumerated()), id: \.element.id) {
                        index, slot in
                        GridSlotItem(
                            slot: slot,
                            number: index + 1,
                            task: slot.taskID.flatMap { tasksByID[$0] },
                            isSelected: selectedSlotID == slot.id,
                            gridSize: layout.gridSize,
                            canvasSize: canvas,
                            onSelect: { onSelectSlot(slot.id) },
                            onAssign: { onAssignSlot(slot.id) },
                            onPlace: { onPlaceSlot(slot.id, $0) }
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
            .animation(LayoutDesign.stateAnimation, value: layout.slots)
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

private struct LayoutGridBackground: View {
    let gridSize: GridSize

    var body: some View {
        Canvas { context, size in
            let color = Color.primary.opacity(0.085)

            for column in 1..<gridSize.columns {
                let x = size.width * CGFloat(column) / CGFloat(gridSize.columns)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 5])
                )
            }

            for row in 1..<gridSize.rows {
                let y = size.height * CGFloat(row) / CGFloat(gridSize.rows)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 5])
                )
            }
        }
        .background(.primary.opacity(0.018))
        .overlay {
            RoundedRectangle(cornerRadius: LayoutDesign.canvasRadius)
                .stroke(.primary.opacity(0.075), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

private struct GridSlotItem: View {
    let slot: LayoutSlot
    let number: Int
    let task: CodexTask?
    let isSelected: Bool
    let gridSize: GridSize
    let canvasSize: CGSize
    let onSelect: () -> Void
    let onAssign: () -> Void
    let onPlace: (GridRect) -> Void

    @State private var draftRect: GridRect?
    @State private var isHovering = false

    private var sourceRect: GridRect {
        GridLayoutEngine.gridRect(for: slot.frame, in: gridSize)
    }

    private var visibleRect: GridRect {
        draftRect ?? sourceRect
    }

    private var cellSize: CGSize {
        CGSize(
            width: canvasSize.width / CGFloat(gridSize.columns),
            height: canvasSize.height / CGFloat(gridSize.rows)
        )
    }

    private var cardSize: CGSize {
        CGSize(
            width: max(
                42,
                cellSize.width * CGFloat(visibleRect.columnSpan)
                    - LayoutDesign.slotGap
            ),
            height: max(
                42,
                cellSize.height * CGFloat(visibleRect.rowSpan)
                    - LayoutDesign.slotGap
            )
        )
    }

    private var cardPosition: CGPoint {
        CGPoint(
            x: cellSize.width
                * (CGFloat(visibleRect.column) + CGFloat(visibleRect.columnSpan) / 2),
            y: cellSize.height
                * (CGFloat(visibleRect.row) + CGFloat(visibleRect.rowSpan) / 2)
        )
    }

    var body: some View {
        slotCard
            .frame(width: cardSize.width, height: cardSize.height)
            .position(cardPosition)
            .zIndex(isSelected || draftRect != nil ? 2 : 1)
            .onHover { hovering in
                withAnimation(LayoutDesign.interactiveAnimation) {
                    isHovering = hovering
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(accessibilityLabelText)
    }

    private var slotCard: some View {
        VStack(spacing: 0) {
            titleBar
            taskContent
        }
        .background {
            ZStack {
                FrostedBackdrop(
                    material: .contentBackground,
                    blendingMode: .withinWindow
                )
                Color.primary.opacity(isHovering ? 0.065 : 0.035)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: LayoutDesign.slotRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LayoutDesign.slotRadius)
                .stroke(
                    isSelected
                        ? Color.accentColor.opacity(0.82)
                        : Color.primary.opacity(0.11),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .overlay(alignment: .bottomTrailing) {
            if isSelected {
                resizeHandle
            }
        }
        .shadow(
            color: .black.opacity(isHovering || isSelected ? 0.14 : 0.07),
            radius: isHovering || isSelected ? 10 : 4,
            y: isHovering || isSelected ? 5 : 2
        )
        .contentShape(RoundedRectangle(cornerRadius: LayoutDesign.slotRadius))
        .onTapGesture(perform: onSelect)
    }

    private var titleBar: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(.primary.opacity(0.18))
                    .frame(width: 6, height: 6)
            }

            Spacer(minLength: 3)

            Text("\(visibleRect.columnSpan)×\(visibleRect.rowSpan)")
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            Text("\(number)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .frame(height: 27)
        .background(.primary.opacity(0.05))
        .contentShape(Rectangle())
        .gesture(moveGesture)
        .help("Drag to move · snaps to the grid")
    }

    private var taskContent: some View {
        Button(action: onAssign) {
            VStack(spacing: 6) {
                Image(systemName: task == nil ? "plus" : "text.bubble.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        task == nil ? Color.secondary.opacity(0.62) : Color.primary
                    )

                Text(task?.title ?? "Choose task")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(task == nil ? Color.secondary : Color.primary)
                    .lineLimit(cardSize.height < 105 ? 1 : 2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                if let task, cardSize.height >= 126 {
                    Text(task.projectName)
                        .font(.system(size: 9.5))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(task == nil ? "Choose a Codex task" : "Change Codex task")
    }

    private var resizeHandle: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.primary)
            .frame(width: 26, height: 26)
            .background(.thickMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(.primary.opacity(0.13), lineWidth: 1)
            }
            .padding(6)
            .contentShape(Circle())
            .gesture(resizeGesture)
            .help("Drag to resize · minimum 1×1")
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                let columnDelta = Int((value.translation.width / cellSize.width).rounded())
                let rowDelta = Int((value.translation.height / cellSize.height).rounded())
                var proposal = sourceRect
                proposal.column += columnDelta
                proposal.row += rowDelta
                draftRect = proposal.clamped(to: gridSize)
            }
            .onEnded { _ in
                let proposal = draftRect ?? sourceRect
                draftRect = nil
                onPlace(proposal)
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let columnDelta = Int((value.translation.width / cellSize.width).rounded())
                let rowDelta = Int((value.translation.height / cellSize.height).rounded())
                var proposal = sourceRect
                proposal.columnSpan += columnDelta
                proposal.rowSpan += rowDelta
                draftRect = proposal.clamped(to: gridSize)
            }
            .onEnded { _ in
                let proposal = draftRect ?? sourceRect
                draftRect = nil
                onPlace(proposal)
            }
    }

    private var accessibilityLabelText: String {
        let assignment = task?.title ?? "unassigned"
        return "Window \(number), \(visibleRect.columnSpan) by \(visibleRect.rowSpan), \(assignment)"
    }
}
