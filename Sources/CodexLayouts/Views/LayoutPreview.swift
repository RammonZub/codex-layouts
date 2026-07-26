import SwiftUI

struct LayoutPreview: View {
    let layout: WorkspaceLayout
    let tasksByID: [String: CodexTask]
    let selectedSlotID: UUID?
    let onSelectSlot: (UUID) -> Void
    let onAssignSlot: (UUID) -> Void
    let onPlaceSlot: (UUID, GridRect) -> Void
    let onRemoveSlot: (UUID) -> Void
    let onAddSlot: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var previewSlots: [LayoutSlot]?
    @State private var activeSlotID: UUID?

    private var displayedSlots: [LayoutSlot] {
        previewSlots ?? layout.slots
    }

    var body: some View {
        GeometryReader { proxy in
            let canvas = fittedCanvas(in: proxy.size)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: LayoutDesign.outerRadius)
                    .fill(.primary.opacity(0.016))
                    .shadow(color: .black.opacity(0.07), radius: 18, y: 8)
                    .overlay {
                        RoundedRectangle(cornerRadius: LayoutDesign.outerRadius)
                            .stroke(.primary.opacity(0.055), lineWidth: 1)
                    }

                ZStack {
                    LayoutGridBackground(gridSize: layout.gridSize)

                    ForEach(Array(displayedSlots.enumerated()), id: \.element.id) {
                        index, slot in
                        GridSlotItem(
                            slot: slot,
                            number: index + 1,
                            task: slot.taskID.flatMap { tasksByID[$0] },
                            isSelected: selectedSlotID == slot.id,
                            isInteracting: activeSlotID == slot.id,
                            canRemove: layout.slots.count > 1,
                            gridSize: layout.gridSize,
                            canvasSize: canvas,
                            onSelect: { onSelectSlot(slot.id) },
                            onAssign: { onAssignSlot(slot.id) },
                            onPreview: { preview(slotID: slot.id, at: $0) },
                            onCommit: { commit(slotID: slot.id, at: $0) },
                            onRemove: { onRemoveSlot(slot.id) }
                        )
                        .transition(.scale(scale: 0.88).combined(with: .opacity))
                    }

                    if activeSlotID == nil,
                       let openSlot = GridLayoutEngine.addingUnitSlot(
                           to: layout.slots,
                           in: layout.gridSize
                       ) {
                        AddGridCellButton(
                            rect: GridLayoutEngine.gridRect(
                                for: openSlot.frame,
                                in: layout.gridSize
                            ),
                            gridSize: layout.gridSize,
                            canvasSize: canvas,
                            action: onAddSlot
                        )
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
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
        .onChange(of: layout.id) { _, _ in
            previewSlots = nil
            activeSlotID = nil
        }
    }

    private func preview(slotID: UUID, at rect: GridRect) {
        activeSlotID = slotID
        guard let result = GridLayoutEngine.reflowing(
            layout.slots,
            moving: slotID,
            to: rect,
            in: layout.gridSize
        ) else {
            return
        }

        if reduceMotion {
            previewSlots = result
        } else {
            withAnimation(LayoutDesign.layoutSpring) {
                previewSlots = result
            }
        }
    }

    private func commit(slotID: UUID, at rect: GridRect) {
        onPlaceSlot(slotID, rect)
        if reduceMotion {
            previewSlots = nil
            activeSlotID = nil
        } else {
            withAnimation(LayoutDesign.layoutSpring) {
                previewSlots = nil
                activeSlotID = nil
            }
        }
    }

    private func fittedCanvas(in size: CGSize) -> CGSize {
        let available = CGSize(
            width: max(1, size.width - (LayoutDesign.cardPadding * 2)),
            height: max(1, size.height - (LayoutDesign.cardPadding * 2))
        )
        let aspectRatio: CGFloat = 16.0 / 9.0
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
            let color = Color.primary.opacity(0.065)

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
        .background(.primary.opacity(0.012))
        .overlay {
            RoundedRectangle(cornerRadius: LayoutDesign.canvasRadius)
                .stroke(.primary.opacity(0.06), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

private struct GridSlotItem: View {
    let slot: LayoutSlot
    let number: Int
    let task: CodexTask?
    let isSelected: Bool
    let isInteracting: Bool
    let canRemove: Bool
    let gridSize: GridSize
    let canvasSize: CGSize
    let onSelect: () -> Void
    let onAssign: () -> Void
    let onPreview: (GridRect) -> Void
    let onCommit: (GridRect) -> Void
    let onRemove: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false
    @State private var isMoving = false
    @State private var isResizing = false
    @State private var moveOrigin: GridRect?
    @State private var resizeOrigin: GridRect?
    @State private var lastMoveProposal: GridRect?
    @State private var lastResizeProposal: GridRect?
    @State private var moveRemainder = CGSize.zero
    @State private var resizeRemainder = CGSize.zero

    private var sourceRect: GridRect {
        GridLayoutEngine.gridRect(for: slot.frame, in: gridSize)
    }

    private var cellSize: CGSize {
        CGSize(
            width: canvasSize.width / CGFloat(gridSize.columns),
            height: canvasSize.height / CGFloat(gridSize.rows)
        )
    }

    private var snappedCardSize: CGSize {
        CGSize(
            width: max(
                42,
                cellSize.width * CGFloat(sourceRect.columnSpan)
                    - LayoutDesign.slotGap
            ),
            height: max(
                42,
                cellSize.height * CGFloat(sourceRect.rowSpan)
                    - LayoutDesign.slotGap
            )
        )
    }

    private var renderedCardSize: CGSize {
        CGSize(
            width: max(42, snappedCardSize.width + resizeRemainder.width),
            height: max(42, snappedCardSize.height + resizeRemainder.height)
        )
    }

    private var snappedCardPosition: CGPoint {
        CGPoint(
            x: cellSize.width
                * (CGFloat(sourceRect.column) + CGFloat(sourceRect.columnSpan) / 2),
            y: cellSize.height
                * (CGFloat(sourceRect.row) + CGFloat(sourceRect.rowSpan) / 2)
        )
    }

    private var renderedCardPosition: CGPoint {
        CGPoint(
            x: snappedCardPosition.x
                + moveRemainder.width
                + resizeRemainder.width / 2,
            y: snappedCardPosition.y
                + moveRemainder.height
                + resizeRemainder.height / 2
        )
    }

    var body: some View {
        slotCard
            .frame(width: renderedCardSize.width, height: renderedCardSize.height)
            .position(renderedCardPosition)
            .scaleEffect(isMoving || isResizing ? 1.012 : 1)
            .opacity(isMoving || isResizing ? 0.97 : 1)
            .zIndex(isSelected || isInteracting ? 3 : 1)
            .animation(
                reduceMotion || isInteracting ? nil : LayoutDesign.layoutSpring,
                value: slot.frame
            )
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
        .allowsHitTesting(false)
        .background {
            ZStack {
                FrostedBackdrop(
                    material: .contentBackground,
                    blendingMode: .withinWindow
                )
                Color.primary.opacity(isHovering || isMoving ? 0.052 : 0.026)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: LayoutDesign.slotRadius))
        .overlay {
            RoundedRectangle(cornerRadius: LayoutDesign.slotRadius)
                .stroke(
                    isSelected
                        ? Color.accentColor.opacity(0.88)
                        : Color.primary.opacity(0.12),
                    lineWidth: isSelected ? 2 : 1
                )
                .allowsHitTesting(false)
        }
        .overlay {
            cardInteractionSurface
        }
        .overlay(alignment: .topLeading) {
            if isSelected && canRemove {
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9.5, weight: .bold))
                        .frame(width: 26, height: 26)
                        .background(.thickMaterial, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(5)
                .help("Remove window")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Button(action: onAssign) {
                    Image(systemName: task == nil ? "plus" : "bubble.left.and.pencil")
                        .font(.system(size: 9.5, weight: .semibold))
                        .frame(width: 26, height: 26)
                        .background(.thickMaterial, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(5)
                .help(task == nil ? "Choose task" : "Change task")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if isSelected {
                resizeHandle
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .shadow(
            color: .black.opacity(
                isMoving || isResizing ? 0.2 : (isHovering || isSelected ? 0.14 : 0.07)
            ),
            radius: isMoving || isResizing ? 16 : (isHovering || isSelected ? 10 : 4),
            y: isMoving || isResizing ? 9 : (isHovering || isSelected ? 5 : 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: LayoutDesign.slotRadius))
        .help("Click to select · drag to move")
    }

    private var titleBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(.primary.opacity(0.13))
                    .frame(width: 5, height: 5)
            }
            Spacer()
        }
        .padding(.horizontal, 9)
        .frame(height: 25)
        .background(.primary.opacity(0.036))
    }

    private var cardInteractionSurface: some View {
        Color.primary.opacity(0.001)
            .contentShape(RoundedRectangle(cornerRadius: LayoutDesign.slotRadius))
            .gesture(moveGesture)
    }

    private var taskContent: some View {
        VStack(spacing: 5) {
            Image(systemName: task == nil ? "plus" : "text.bubble.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    task == nil ? Color.secondary.opacity(0.32) : Color.primary
                )

            if let task {
                Text(task.title)
                    .font(.system(size: 10.5, weight: .medium))
                    .lineLimit(renderedCardSize.height < 108 ? 1 : 2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resizeHandle: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.primary)
            .frame(width: 30, height: 30)
            .background(.thickMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(.primary.opacity(0.16), lineWidth: 1)
            }
            .padding(7)
            .contentShape(Circle())
            .highPriorityGesture(resizeGesture)
            .help("Drag to resize · minimum 1×1")
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let origin: GridRect
                if let moveOrigin {
                    origin = moveOrigin
                } else {
                    origin = sourceRect
                    moveOrigin = sourceRect
                    onSelect()
                }

                guard abs(value.translation.width) >= 3
                        || abs(value.translation.height) >= 3 else {
                    return
                }
                isMoving = true

                let columnDelta = Int((value.translation.width / cellSize.width).rounded())
                let rowDelta = Int((value.translation.height / cellSize.height).rounded())
                let proposal = GridRect(
                    column: origin.column + columnDelta,
                    row: origin.row + rowDelta,
                    columnSpan: origin.columnSpan,
                    rowSpan: origin.rowSpan
                )
                .clamped(to: gridSize)

                lastMoveProposal = proposal
                moveRemainder = CGSize(
                    width: value.translation.width
                        - CGFloat(proposal.column - origin.column) * cellSize.width,
                    height: value.translation.height
                        - CGFloat(proposal.row - origin.row) * cellSize.height
                )
                onPreview(proposal)
            }
            .onEnded { _ in
                guard moveOrigin != nil else { return }
                if let proposal = lastMoveProposal {
                    onCommit(proposal)
                }
                settleMoveState()
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                let origin: GridRect
                if let resizeOrigin {
                    origin = resizeOrigin
                } else {
                    origin = sourceRect
                    resizeOrigin = sourceRect
                    isResizing = true
                    onSelect()
                }

                let columnDelta = Int((value.translation.width / cellSize.width).rounded())
                let rowDelta = Int((value.translation.height / cellSize.height).rounded())
                let proposal = GridRect(
                    column: origin.column,
                    row: origin.row,
                    columnSpan: min(
                        max(1, origin.columnSpan + columnDelta),
                        gridSize.columns - origin.column
                    ),
                    rowSpan: min(
                        max(1, origin.rowSpan + rowDelta),
                        gridSize.rows - origin.row
                    )
                )

                lastResizeProposal = proposal
                resizeRemainder = CGSize(
                    width: value.translation.width
                        - CGFloat(proposal.columnSpan - origin.columnSpan) * cellSize.width,
                    height: value.translation.height
                        - CGFloat(proposal.rowSpan - origin.rowSpan) * cellSize.height
                )
                onPreview(proposal)
            }
            .onEnded { _ in
                let proposal = lastResizeProposal ?? resizeOrigin ?? sourceRect
                onCommit(proposal)
                settleResizeState()
            }
    }

    private func settleMoveState() {
        let changes = {
            moveRemainder = .zero
            isMoving = false
        }
        if reduceMotion {
            changes()
        } else {
            withAnimation(LayoutDesign.layoutSpring) {
                changes()
            }
        }
        moveOrigin = nil
        lastMoveProposal = nil
    }

    private func settleResizeState() {
        let changes = {
            resizeRemainder = .zero
            isResizing = false
        }
        if reduceMotion {
            changes()
        } else {
            withAnimation(LayoutDesign.layoutSpring) {
                changes()
            }
        }
        resizeOrigin = nil
        lastResizeProposal = nil
    }

    private var accessibilityLabelText: String {
        let assignment = task?.title ?? "unassigned"
        return "Window \(number), \(sourceRect.columnSpan) by \(sourceRect.rowSpan), \(assignment)"
    }
}

private struct AddGridCellButton: View {
    let rect: GridRect
    let gridSize: GridSize
    let canvasSize: CGSize
    let action: () -> Void

    @State private var isHovering = false

    private var cellSize: CGSize {
        CGSize(
            width: canvasSize.width / CGFloat(gridSize.columns),
            height: canvasSize.height / CGFloat(gridSize.rows)
        )
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
            .frame(
                width: max(42, cellSize.width - LayoutDesign.slotGap),
                height: max(42, cellSize.height - LayoutDesign.slotGap)
            )
            .background(
                .primary.opacity(isHovering ? 0.045 : 0.01),
                in: RoundedRectangle(cornerRadius: LayoutDesign.slotRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: LayoutDesign.slotRadius)
                    .stroke(
                        .primary.opacity(isHovering ? 0.25 : 0.10),
                        style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: LayoutDesign.slotRadius))
        }
        .buttonStyle(PressScaleButtonStyle())
        .position(
            x: cellSize.width * (CGFloat(rect.column) + 0.5),
            y: cellSize.height * (CGFloat(rect.row) + 0.5)
        )
        .zIndex(0)
        .onHover { hovering in
            withAnimation(LayoutDesign.interactiveAnimation) {
                isHovering = hovering
            }
        }
        .help("Add a 1×1 window here")
    }
}
