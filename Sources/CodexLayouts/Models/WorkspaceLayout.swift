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
    var isStarter: Bool

    init(id: UUID = UUID(), name: String, slots: [LayoutSlot], isStarter: Bool = false) {
        self.id = id
        self.name = name
        self.slots = slots
        self.isStarter = isStarter
    }
}

extension WorkspaceLayout {
    static let starters: [WorkspaceLayout] = [
        WorkspaceLayout(
            name: "Focus + Stack",
            slots: [
                LayoutSlot(frame: .init(x: 0, y: 0, width: 0.62, height: 1)),
                LayoutSlot(frame: .init(x: 0.62, y: 0, width: 0.38, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.62, y: 0.5, width: 0.38, height: 0.5))
            ],
            isStarter: true
        ),
        WorkspaceLayout(
            name: "Focus + Four",
            slots: [
                LayoutSlot(frame: .init(x: 0, y: 0, width: 0.62, height: 1)),
                LayoutSlot(frame: .init(x: 0.62, y: 0, width: 0.38, height: 0.25)),
                LayoutSlot(frame: .init(x: 0.62, y: 0.25, width: 0.38, height: 0.25)),
                LayoutSlot(frame: .init(x: 0.62, y: 0.5, width: 0.38, height: 0.25)),
                LayoutSlot(frame: .init(x: 0.62, y: 0.75, width: 0.38, height: 0.25))
            ],
            isStarter: true
        ),
        WorkspaceLayout(
            name: "Focus + Grid",
            slots: [
                LayoutSlot(frame: .init(x: 0, y: 0, width: 0.56, height: 1)),
                LayoutSlot(frame: .init(x: 0.56, y: 0, width: 0.22, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.78, y: 0, width: 0.22, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.56, y: 0.5, width: 0.22, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.78, y: 0.5, width: 0.22, height: 0.5))
            ],
            isStarter: true
        ),
        WorkspaceLayout(
            name: "Three Columns",
            slots: [
                LayoutSlot(frame: .init(x: 0, y: 0, width: 1.0 / 3.0, height: 1)),
                LayoutSlot(frame: .init(x: 1.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1)),
                LayoutSlot(frame: .init(x: 2.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1))
            ],
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
            isStarter: true
        )
    ]
}
