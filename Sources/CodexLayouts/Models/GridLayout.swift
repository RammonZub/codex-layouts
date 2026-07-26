import Foundation

struct GridSize: Codable, Equatable, Hashable, Sendable {
    let columns: Int
    let rows: Int

    init(columns: Int, rows: Int) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)
    }

    static let canvasDefault = GridSize(columns: 4, rows: 4)

    static let editorPresets = [
        GridSize(columns: 2, rows: 2),
        GridSize(columns: 3, rows: 2),
        GridSize(columns: 3, rows: 3),
        GridSize(columns: 4, rows: 3),
        GridSize(columns: 4, rows: 4),
        GridSize(columns: 5, rows: 4),
        GridSize(columns: 6, rows: 4)
    ]

    static func inferred(from frames: [NormalizedRect]) -> GridSize {
        GridSize(
            columns: bestDivision(for: frames.flatMap { [$0.x, $0.x + $0.width] }),
            rows: bestDivision(for: frames.flatMap { [$0.y, $0.y + $0.height] })
        )
    }

    private static func bestDivision(for values: [Double]) -> Int {
        (1...6).min { lhs, rhs in
            quantizationError(values, divisions: lhs)
                < quantizationError(values, divisions: rhs)
        } ?? 1
    }

    private static func quantizationError(_ values: [Double], divisions: Int) -> Double {
        values.reduce(0) { result, value in
            let scaled = value * Double(divisions)
            return result + abs(scaled - scaled.rounded())
        }
    }
}

struct GridRect: Codable, Equatable, Hashable, Sendable {
    var column: Int
    var row: Int
    var columnSpan: Int
    var rowSpan: Int

    var maxColumn: Int { column + columnSpan }
    var maxRow: Int { row + rowSpan }
    var area: Int { columnSpan * rowSpan }

    func intersects(_ other: GridRect) -> Bool {
        column < other.maxColumn
            && maxColumn > other.column
            && row < other.maxRow
            && maxRow > other.row
    }

    func clamped(to grid: GridSize) -> GridRect {
        let width = min(max(1, columnSpan), grid.columns)
        let height = min(max(1, rowSpan), grid.rows)
        return GridRect(
            column: min(max(0, column), grid.columns - width),
            row: min(max(0, row), grid.rows - height),
            columnSpan: width,
            rowSpan: height
        )
    }
}
