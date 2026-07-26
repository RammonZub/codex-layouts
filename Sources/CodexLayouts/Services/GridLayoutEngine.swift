import Foundation

enum GridLayoutEngine {
    static func gridRect(for frame: NormalizedRect, in grid: GridSize) -> GridRect {
        let startColumn = Int((frame.x * Double(grid.columns)).rounded())
        let endColumn = Int(((frame.x + frame.width) * Double(grid.columns)).rounded())
        let startRow = Int((frame.y * Double(grid.rows)).rounded())
        let endRow = Int(((frame.y + frame.height) * Double(grid.rows)).rounded())

        return GridRect(
            column: startColumn,
            row: startRow,
            columnSpan: max(1, endColumn - startColumn),
            rowSpan: max(1, endRow - startRow)
        )
        .clamped(to: grid)
    }

    static func normalizedRect(for rect: GridRect, in grid: GridSize) -> NormalizedRect {
        let rect = rect.clamped(to: grid)
        return NormalizedRect(
            x: Double(rect.column) / Double(grid.columns),
            y: Double(rect.row) / Double(grid.rows),
            width: Double(rect.columnSpan) / Double(grid.columns),
            height: Double(rect.rowSpan) / Double(grid.rows)
        )
    }

    static func reflowing(
        _ slots: [LayoutSlot],
        moving slotID: UUID,
        to proposedRect: GridRect,
        in grid: GridSize
    ) -> [LayoutSlot]? {
        guard slots.contains(where: { $0.id == slotID }) else {
            return nil
        }

        let movingRect = proposedRect.clamped(to: grid)
        var placements = [slotID: movingRect]
        var occupied = [movingRect]

        for slot in slots where slot.id != slotID {
            let desired = gridRect(for: slot.frame, in: grid)
            let placement: GridRect
            if isAvailable(desired, occupied: occupied) {
                placement = desired
            } else if let vacancy = nearestVacancy(
                matching: desired,
                in: grid,
                occupied: occupied
            ) {
                placement = vacancy
            } else {
                return nil
            }
            placements[slot.id] = placement
            occupied.append(placement)
        }

        return slots.map { slot in
            var updated = slot
            if let placement = placements[slot.id] {
                updated.frame = normalizedRect(for: placement, in: grid)
            }
            return updated
        }
    }

    static func addingUnitSlot(
        to slots: [LayoutSlot],
        in grid: GridSize
    ) -> LayoutSlot? {
        let occupied = slots.map { gridRect(for: $0.frame, in: grid) }
        let unit = GridRect(column: 0, row: 0, columnSpan: 1, rowSpan: 1)
        guard let vacancy = nearestVacancy(
            matching: unit,
            in: grid,
            occupied: occupied
        ) else {
            return nil
        }
        return LayoutSlot(frame: normalizedRect(for: vacancy, in: grid))
    }

    static func addingUnitSlot(
        at rect: GridRect,
        to slots: [LayoutSlot],
        in grid: GridSize
    ) -> LayoutSlot? {
        let unit = GridRect(
            column: rect.column,
            row: rect.row,
            columnSpan: 1,
            rowSpan: 1
        )
        .clamped(to: grid)
        let occupied = slots.map { gridRect(for: $0.frame, in: grid) }
        guard isAvailable(unit, occupied: occupied) else {
            return nil
        }
        return LayoutSlot(frame: normalizedRect(for: unit, in: grid))
    }

    static func vacantUnitRects(
        around slots: [LayoutSlot],
        in grid: GridSize
    ) -> [GridRect] {
        let occupied = slots.map { gridRect(for: $0.frame, in: grid) }
        return (0..<grid.rows).flatMap { row in
            (0..<grid.columns).compactMap { column in
                let unit = GridRect(
                    column: column,
                    row: row,
                    columnSpan: 1,
                    rowSpan: 1
                )
                return isAvailable(unit, occupied: occupied) ? unit : nil
            }
        }
    }

    static func regridding(
        _ slots: [LayoutSlot],
        from sourceGrid: GridSize,
        to targetGrid: GridSize
    ) -> [LayoutSlot]? {
        var occupied: [GridRect] = []
        var placements: [UUID: GridRect] = [:]

        for slot in slots {
            let sourceRect = gridRect(for: slot.frame, in: sourceGrid)
            let desired = GridRect(
                column: Int(
                    (Double(sourceRect.column) / Double(sourceGrid.columns)
                        * Double(targetGrid.columns)).rounded()
                ),
                row: Int(
                    (Double(sourceRect.row) / Double(sourceGrid.rows)
                        * Double(targetGrid.rows)).rounded()
                ),
                columnSpan: max(
                    1,
                    Int(
                        (Double(sourceRect.columnSpan) / Double(sourceGrid.columns)
                            * Double(targetGrid.columns)).rounded()
                    )
                ),
                rowSpan: max(
                    1,
                    Int(
                        (Double(sourceRect.rowSpan) / Double(sourceGrid.rows)
                            * Double(targetGrid.rows)).rounded()
                    )
                )
            )
            .clamped(to: targetGrid)

            let placement: GridRect
            if isAvailable(desired, occupied: occupied) {
                placement = desired
            } else if let vacancy = nearestVacancy(
                matching: desired,
                in: targetGrid,
                occupied: occupied
            ) {
                placement = vacancy
            } else {
                return nil
            }
            placements[slot.id] = placement
            occupied.append(placement)
        }

        return slots.map { slot in
            var updated = slot
            if let placement = placements[slot.id] {
                updated.frame = normalizedRect(for: placement, in: targetGrid)
            }
            return updated
        }
    }

    private static func nearestVacancy(
        matching desired: GridRect,
        in grid: GridSize,
        occupied: [GridRect]
    ) -> GridRect? {
        guard desired.columnSpan <= grid.columns, desired.rowSpan <= grid.rows else {
            return nil
        }

        var candidates: [GridRect] = []
        for row in 0...(grid.rows - desired.rowSpan) {
            for column in 0...(grid.columns - desired.columnSpan) {
                let candidate = GridRect(
                    column: column,
                    row: row,
                    columnSpan: desired.columnSpan,
                    rowSpan: desired.rowSpan
                )
                if isAvailable(candidate, occupied: occupied) {
                    candidates.append(candidate)
                }
            }
        }

        return candidates.min { lhs, rhs in
            let lhsDistance = abs(lhs.column - desired.column) + abs(lhs.row - desired.row)
            let rhsDistance = abs(rhs.column - desired.column) + abs(rhs.row - desired.row)
            if lhsDistance != rhsDistance {
                return lhsDistance < rhsDistance
            }
            if lhs.row != rhs.row {
                return lhs.row < rhs.row
            }
            return lhs.column < rhs.column
        }
    }

    private static func isAvailable(_ candidate: GridRect, occupied: [GridRect]) -> Bool {
        !occupied.contains(where: candidate.intersects)
    }
}
