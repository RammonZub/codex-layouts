import Foundation
import Testing
@testable import CodexLayouts

@Suite("Snap-to-grid layout engine")
struct GridLayoutEngineTests {
    @Test("Normalized frames round-trip through grid cells")
    func roundTrip() {
        let grid = GridSize(columns: 5, rows: 4)
        let gridRect = GridRect(column: 3, row: 2, columnSpan: 2, rowSpan: 2)

        let frame = GridLayoutEngine.normalizedRect(for: gridRect, in: grid)

        #expect(GridLayoutEngine.gridRect(for: frame, in: grid) == gridRect)
    }

    @Test("Dropping onto an occupied cell shifts the other window")
    func collisionReflow() {
        let grid = GridSize(columns: 2, rows: 1)
        let first = LayoutSlot(
            frame: .init(x: 0, y: 0, width: 0.5, height: 1)
        )
        let second = LayoutSlot(
            frame: .init(x: 0.5, y: 0, width: 0.5, height: 1)
        )

        let result = GridLayoutEngine.reflowing(
            [first, second],
            moving: first.id,
            to: GridRect(column: 1, row: 0, columnSpan: 1, rowSpan: 1),
            in: grid
        )

        #expect(result != nil)
        #expect(
            result.map {
                GridLayoutEngine.gridRect(for: $0[0].frame, in: grid).column
            } == 1
        )
        #expect(
            result.map {
                GridLayoutEngine.gridRect(for: $0[1].frame, in: grid).column
            } == 0
        )
    }

    @Test("A resize is rejected when displaced windows cannot fit")
    func rejectsImpossibleResize() {
        let grid = GridSize(columns: 2, rows: 1)
        let first = LayoutSlot(
            frame: .init(x: 0, y: 0, width: 0.5, height: 1)
        )
        let second = LayoutSlot(
            frame: .init(x: 0.5, y: 0, width: 0.5, height: 1)
        )

        let result = GridLayoutEngine.reflowing(
            [first, second],
            moving: first.id,
            to: GridRect(column: 0, row: 0, columnSpan: 2, rowSpan: 1),
            in: grid
        )

        #expect(result == nil)
    }

    @Test("New windows begin at the smallest free one-by-one cell")
    func addsOneByOneWindow() {
        let grid = GridSize(columns: 2, rows: 2)
        let existing = LayoutSlot(
            frame: .init(x: 0, y: 0, width: 0.5, height: 0.5)
        )

        let added = GridLayoutEngine.addingUnitSlot(to: [existing], in: grid)
        let addedRect = added.map {
            GridLayoutEngine.gridRect(for: $0.frame, in: grid)
        }

        #expect(
            addedRect == GridRect(
                column: 1,
                row: 0,
                columnSpan: 1,
                rowSpan: 1
            )
        )
    }

    @Test("Every empty unit cell is available as an add target")
    func exposesEveryEmptyCell() {
        let grid = GridSize(columns: 4, rows: 2)
        let existing = LayoutSlot(
            frame: .init(x: 0, y: 0, width: 0.5, height: 1)
        )

        let vacancies = GridLayoutEngine.vacantUnitRects(
            around: [existing],
            in: grid
        )

        #expect(vacancies.count == 4)
        #expect(vacancies.first == GridRect(
            column: 2,
            row: 0,
            columnSpan: 1,
            rowSpan: 1
        ))
        #expect(vacancies.last == GridRect(
            column: 3,
            row: 1,
            columnSpan: 1,
            rowSpan: 1
        ))
    }

    @Test("A window can be added to the chosen empty cell")
    func addsAtChosenCell() {
        let grid = GridSize(columns: 4, rows: 2)
        let desired = GridRect(
            column: 3,
            row: 1,
            columnSpan: 1,
            rowSpan: 1
        )

        let added = GridLayoutEngine.addingUnitSlot(
            at: desired,
            to: [],
            in: grid
        )

        #expect(
            added.map { GridLayoutEngine.gridRect(for: $0.frame, in: grid) }
                == desired
        )
    }
}
