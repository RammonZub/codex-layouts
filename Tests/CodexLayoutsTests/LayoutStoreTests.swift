import Foundation
import Testing
@testable import CodexLayouts

@Suite("Layout persistence")
struct LayoutStoreTests {
    @Test("Missing storage starts with the curated layouts")
    func defaultsToStarterLayouts() throws {
        let fileURL = temporaryFileURL()
        let store = LayoutStore(fileURL: fileURL)

        let layouts = try store.load()

        #expect(layouts.map(\.name) == WorkspaceLayout.starters.map(\.name))
    }

    @Test("Saved layouts round-trip without losing assignments")
    func roundTrip() throws {
        let fileURL = temporaryFileURL()
        let store = LayoutStore(fileURL: fileURL)
        var layout = WorkspaceLayout.starters[0]
        layout.slots[0].taskID = "thread-123"

        try store.save([layout])
        let restored = try store.load()

        #expect(restored == [layout])
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test("Legacy focus grid migrates without losing the four-stack starter")
    func migratesLegacyFocusGrid() throws {
        let fileURL = temporaryFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let legacyGrid = WorkspaceLayout(
            name: "Focus + Four",
            slots: [
                LayoutSlot(frame: .init(x: 0, y: 0, width: 0.6, height: 1)),
                LayoutSlot(frame: .init(x: 0.6, y: 0, width: 0.2, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.8, y: 0, width: 0.2, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.6, y: 0.5, width: 0.2, height: 0.5)),
                LayoutSlot(frame: .init(x: 0.8, y: 0.5, width: 0.2, height: 0.5))
            ],
            gridSize: .init(columns: 5, rows: 4),
            isStarter: true
        )
        let legacyData = try JSONEncoder().encode([legacyGrid])
        try legacyData.write(to: fileURL)

        let layouts = try LayoutStore(fileURL: fileURL).load()

        #expect(layouts.contains { $0.name == "Focus + Grid" })
        #expect(layouts.contains { $0.name == "Focus + Four" })
        #expect(
            layouts.first { $0.name == "Focus + Four" }?.gridSize
                == GridSize(columns: 4, rows: 2)
        )
        #expect(
            layouts.first { $0.name == "Focus + Four" }?.slots[1].frame.height
                == 0.5
        )
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    @Test("Two-by-two layouts gain four columns without changing their shape")
    func migratesTwoByTwoLayouts() throws {
        let fileURL = temporaryFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let layout = WorkspaceLayout(
            name: "Custom",
            slots: [
                LayoutSlot(frame: .init(x: 0, y: 0, width: 0.5, height: 1)),
                LayoutSlot(frame: .init(x: 0.5, y: 0, width: 0.5, height: 0.5))
            ],
            gridSize: .init(columns: 2, rows: 2)
        )
        try JSONEncoder().encode([layout]).write(to: fileURL)

        let migrated = try LayoutStore(fileURL: fileURL).load().first {
            $0.name == "Custom"
        }

        #expect(migrated?.gridSize == GridSize(columns: 4, rows: 2))
        #expect(migrated?.slots.map(\.frame) == layout.slots.map(\.frame))
        try? FileManager.default.removeItem(
            at: fileURL.deletingLastPathComponent()
        )
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "CodexLayoutsTests-\(UUID().uuidString)")
            .appending(path: "layouts.json")
    }
}
