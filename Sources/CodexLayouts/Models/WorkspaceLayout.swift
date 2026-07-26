import Foundation

struct LayoutSlot: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var frame: NormalizedRect
    var taskID: String?

    init(id: UUID = UUID(), frame: NormalizedRect, taskID: String? = nil) {
        self.id = id
        self.frame = frame
        self.taskID = taskID
    }
}

struct WorkspaceLayout: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var slots: [LayoutSlot]
    var gridSize: GridSize
    var isStarter: Bool

    init(
        id: UUID = UUID(),
        name: String,
        slots: [LayoutSlot],
        gridSize: GridSize? = nil,
        isStarter: Bool = false
    ) {
        self.id = id
        self.name = name
        self.slots = slots
        self.gridSize = gridSize ?? GridSize.inferred(from: slots.map(\.frame))
        self.isStarter = isStarter
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case slots
        case gridSize
        case isStarter
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slots = try container.decode([LayoutSlot].self, forKey: .slots)
        gridSize = try container.decodeIfPresent(GridSize.self, forKey: .gridSize)
            ?? GridSize.inferred(from: slots.map(\.frame))
        isStarter = try container.decodeIfPresent(Bool.self, forKey: .isStarter) ?? false
    }
}

extension WorkspaceLayout {
    static let starters: [WorkspaceLayout] = [
        WorkspaceLayout(
            name: "Focus + Stack",
            slots: [
                LayoutSlot(frame: .init(x: 0, y: 0, width: 0.5, height: 1)),
                LayoutSlot(frame: .init(x: 0.5, y: 0, width: 0.5, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
            ],
            gridSize: .init(columns: 4, rows: 2),
            isStarter: true
        ),
        WorkspaceLayout(
            name: "Focus + Four",
            slots: [
                LayoutSlot(frame: .init(x: 0, y: 0, width: 0.5, height: 1)),
                LayoutSlot(frame: .init(x: 0.5, y: 0, width: 0.25, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.75, y: 0, width: 0.25, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.5, y: 0.5, width: 0.25, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.75, y: 0.5, width: 0.25, height: 0.5))
            ],
            gridSize: .init(columns: 4, rows: 2),
            isStarter: true
        ),
        WorkspaceLayout(
            name: "Focus + Grid",
            slots: (0..<8).map { index in
                LayoutSlot(
                    frame: .init(
                        x: Double(index % 4) / 4,
                        y: Double(index / 4) / 2,
                        width: 0.25,
                        height: 0.5
                    )
                )
            },
            gridSize: .init(columns: 4, rows: 2),
            isStarter: true
        ),
        WorkspaceLayout(
            name: "Three Columns",
            slots: [
                LayoutSlot(frame: .init(x: 0, y: 0, width: 1.0 / 3.0, height: 1)),
                LayoutSlot(frame: .init(x: 1.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1)),
                LayoutSlot(frame: .init(x: 2.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1))
            ],
            gridSize: .init(columns: 3, rows: 1),
            isStarter: true
        ),
        WorkspaceLayout(
            name: "Four Grid",
            slots: [
                LayoutSlot(frame: .init(x: 0, y: 0, width: 0.5, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.5, y: 0, width: 0.5, height: 0.5)),
                LayoutSlot(frame: .init(x: 0, y: 0.5, width: 0.5, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
            ],
            gridSize: .init(columns: 4, rows: 2),
            isStarter: true
        )
    ]
}
