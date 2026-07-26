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
        var legacyGrid = WorkspaceLayout.starters.first {
            $0.name == "Focus + Grid"
        }!
        legacyGrid.name = "Focus + Four"
        let legacyData = try JSONEncoder().encode([legacyGrid])
        try legacyData.write(to: fileURL)

        let layouts = try LayoutStore(fileURL: fileURL).load()

        #expect(layouts.contains { $0.name == "Focus + Grid" })
        #expect(layouts.contains { $0.name == "Focus + Four" })
        #expect(
            layouts.first { $0.name == "Focus + Four" }?.slots[1].frame.height
                == 0.25
        )
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
