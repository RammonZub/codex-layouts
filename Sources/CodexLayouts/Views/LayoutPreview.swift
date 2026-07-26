import SwiftUI

private enum LayoutCanvasCoordinateSpace {
    static let name = "layout-canvas"
}

struct LayoutPreview: View {
    let layout: WorkspaceLayout
    let tasksByID: [String: CodexTask]
    let selectedSlotID: UUID?
    let onSelectSlot: (UUID) -> Void
    let onAssignSlot: (UUID) -> Void
    let onPlaceSlot: (UUID, GridRect) -> Void
    let onRemoveSlot: (UUID) -> Void
    let onAddSlot: (GridRect) -> Void

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

                    if activeSlotID == nil {
                        let vacancies = GridLayoutEngine.vacantUnitRects(
                            around: layout.slots,
                            in: layout.gridSize
                        )
                        ForEach(
                            Array(vacancies.enumerated()),
                            id: \.element
                        ) { index, openRect in
                            AddGridCellButton(
                                rect: openRect,
                                gridSize: layout.gridSize,
                                canvasSize: canvas,
                                showsHint: index == 0,
                                action: { onAddSlot(openRect) }
                            )
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                        }
                    }
                }
                .frame(width: canvas.width, height: canvas.height)
                .clipShape(RoundedRectangle(cornerRadius: LayoutDesign.canvasRadius))
                .coordinateSpace(name: LayoutCanvasCoordinateSpace.name)
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

        previewSlots = result
    }

    private func commit(slotID: UUID, at rect: GridRect) {
        onPlaceSlot(slotID, rect)
        previewSlots = nil
        activeSlotID = nil
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
    @State private var interaction = GridInteractionState()
    @State private var lastMoveProposal: GridRect?
    @State private var lastResizeProposal: GridRect?
    @State private var moveTranslation = CGSize.zero

    private var isMoving: Bool {
        interaction.activeKind == .move
    }

    private var isResizing: Bool {
        interaction.activeKind == .resize
    }

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
        snappedCardSize
    }

    private var snappedCardPosition: CGPoint {
        cardPosition(for: sourceRect)
    }

    private func cardPosition(for rect: GridRect) -> CGPoint {
        CGPoint(
            x: cellSize.width
                * (CGFloat(rect.column) + CGFloat(rect.columnSpan) / 2),
            y: cellSize.height
                * (CGFloat(rect.row) + CGFloat(rect.rowSpan) / 2)
        )
    }

    private var renderedCardPosition: CGPoint {
        guard let moveOrigin = interaction.origin(for: .move) else {
            return snappedCardPosition
        }
        let originPosition = cardPosition(for: moveOrigin)
        return CGPoint(
            x: originPosition.x + moveTranslation.width,
            y: originPosition.y + moveTranslation.height
        )
    }

    var body: some View {
        slotCard
            .frame(width: renderedCardSize.width, height: renderedCardSize.height)
            .position(renderedCardPosition)
            .scaleEffect(isMoving ? 1.012 : 1)
            .opacity(isMoving ? 0.97 : 1)
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
        .help("Click to select · drag to move · pinch to resize")
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
        Button(action: onSelect) {
            RoundedRectangle(cornerRadius: LayoutDesign.slotRadius)
                .fill(.clear)
                .contentShape(
                    RoundedRectangle(cornerRadius: LayoutDesign.slotRadius)
                )
        }
            .buttonStyle(.plain)
            .simultaneousGesture(moveGesture)
            .simultaneousGesture(magnifyGesture)
            .accessibilityLabel("Select window \(number)")
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
        WidgetCornerGrip()
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .highPriorityGesture(resizeGesture)
            .help("Drag the corner to resize · snaps after 30%")
    }

    private var moveGesture: some Gesture {
        DragGesture(
            minimumDistance: 3,
            coordinateSpace: .named(LayoutCanvasCoordinateSpace.name)
        )
            .onChanged { value in
                let isBeginning = interaction.activeKind == nil
                guard let origin = interaction.begin(.move, at: sourceRect) else {
                    return
                }
                if isBeginning {
                    onSelect()
                }

                moveTranslation = value.translation

                let columnDelta = Int(
                    (value.translation.width / cellSize.width).rounded()
                )
                let rowDelta = Int(
                    (value.translation.height / cellSize.height).rounded()
                )
                let proposal = GridRect(
                    column: origin.column + columnDelta,
                    row: origin.row + rowDelta,
                    columnSpan: origin.columnSpan,
                    rowSpan: origin.rowSpan
                )
                .clamped(to: gridSize)

                guard proposal != lastMoveProposal else {
                    return
                }
                lastMoveProposal = proposal
                onPreview(proposal)
            }
            .onEnded { _ in
                guard interaction.activeKind == .move else {
                    return
                }
                if let proposal = lastMoveProposal {
                    onCommit(proposal)
                }
                settleMoveState()
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(
            minimumDistance: 3,
            coordinateSpace: .named(LayoutCanvasCoordinateSpace.name)
        )
            .onChanged { value in
                let isBeginning = interaction.activeKind == nil
                guard let origin = interaction.begin(.resize, at: sourceRect) else {
                    return
                }
                if isBeginning {
                    onSelect()
                }

                let columnDelta = GridLayoutEngine.snappedResizeDelta(
                    for: Double(value.translation.width / cellSize.width)
                )
                let rowDelta = GridLayoutEngine.snappedResizeDelta(
                    for: Double(value.translation.height / cellSize.height)
                )
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

                guard proposal != lastResizeProposal else {
                    return
                }
                lastResizeProposal = proposal
                onPreview(proposal)
            }
            .onEnded { _ in
                guard interaction.activeKind == .resize,
                      let origin = interaction.origin(for: .resize) else {
                    return
                }
                let proposal = lastResizeProposal ?? origin
                onCommit(proposal)
                settleResizeState()
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.02)
            .onChanged { value in
                let isBeginning = interaction.activeKind == nil
                guard let origin = interaction.begin(.resize, at: sourceRect) else {
                    return
                }
                if isBeginning {
                    onSelect()
                }

                let columnDelta = GridLayoutEngine.snappedResizeDelta(
                    for: Double(
                        CGFloat(origin.columnSpan)
                            * (value.magnification - 1)
                    )
                )
                let rowDelta = GridLayoutEngine.snappedResizeDelta(
                    for: Double(
                        CGFloat(origin.rowSpan)
                            * (value.magnification - 1)
                    )
                )
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

                guard proposal != lastResizeProposal else {
                    return
                }
                lastResizeProposal = proposal
                onPreview(proposal)
            }
            .onEnded { _ in
                guard interaction.activeKind == .resize,
                      let origin = interaction.origin(for: .resize) else {
                    return
                }
                let proposal = lastResizeProposal ?? origin
                onCommit(proposal)
                settleResizeState()
            }
    }

    private func settleMoveState() {
        moveTranslation = .zero
        interaction.end(.move)
        lastMoveProposal = nil
    }

    private func settleResizeState() {
        interaction.end(.resize)
        lastResizeProposal = nil
    }

    private var accessibilityLabelText: String {
        let assignment = task?.title ?? "unassigned"
        return "Window \(number), \(sourceRect.columnSpan) by \(sourceRect.rowSpan), \(assignment)"
    }
}

private struct WidgetCornerGrip: View {
    var body: some View {
        WidgetCornerGripShape()
            .stroke(
                Color.primary.opacity(0.38),
                style: StrokeStyle(
                    lineWidth: 4.5,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .overlay {
                WidgetCornerGripShape()
                    .stroke(
                        Color.white.opacity(0.55),
                        style: StrokeStyle(
                            lineWidth: 1,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            }
            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            .padding(9)
    }
}

private struct WidgetCornerGripShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(LayoutDesign.slotRadius, min(rect.width, rect.height) / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - radius),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(
            to: CGPoint(x: rect.maxX, y: rect.minY)
        )
        return path
    }
}

private struct AddGridCellButton: View {
    let rect: GridRect
    let gridSize: GridSize
    let canvasSize: CGSize
    let showsHint: Bool
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
                .opacity(isHovering || showsHint ? 1 : 0)
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
