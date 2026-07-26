import Foundation

struct LayoutStore {
    private struct LayoutDocument: Codable {
        var schemaVersion: Int
        var layouts: [WorkspaceLayout]
    }

    private static let currentSchemaVersion = 3

    let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
            return
        }

        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        self.fileURL = applicationSupport
            .appending(path: "CodexLayouts", directoryHint: .isDirectory)
            .appending(path: "layouts.json")
    }

    func load() throws -> [WorkspaceLayout] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return WorkspaceLayout.starters
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let document: LayoutDocument
        if let current = try? decoder.decode(LayoutDocument.self, from: data) {
            document = current
        } else {
            document = LayoutDocument(
                schemaVersion: 0,
                layouts: try decoder.decode([WorkspaceLayout].self, from: data)
            )
        }

        let migrated = migrate(document)
        if migrated.schemaVersion != document.schemaVersion
            || migrated.layouts != document.layouts {
            try write(migrated)
        }
        return migrated.layouts
    }

    func save(_ layouts: [WorkspaceLayout]) throws {
        try write(
            LayoutDocument(
                schemaVersion: Self.currentSchemaVersion,
                layouts: layouts
            )
        )
    }

    private func write(_ document: LayoutDocument) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: fileURL, options: .atomic)
    }

    private func migrate(_ document: LayoutDocument) -> LayoutDocument {
        var layouts = document.layouts

        if document.schemaVersion < 2,
           let oldGridIndex = layouts.firstIndex(where: isLegacyFocusGrid) {
            layouts[oldGridIndex].name = "Focus + Grid"
        }

        if document.schemaVersion < 2 {
            let existingNames = Set(layouts.map(\.name))
            layouts.append(
                contentsOf: WorkspaceLayout.starters.filter {
                    !existingNames.contains($0.name)
                }
            )
        }

        if document.schemaVersion < 3 {
            for layoutIndex in layouts.indices {
                let gridSize = layouts[layoutIndex].gridSize
                for slotIndex in layouts[layoutIndex].slots.indices {
                    let frame = layouts[layoutIndex].slots[slotIndex].frame
                    let gridRect = GridLayoutEngine.gridRect(for: frame, in: gridSize)
                    layouts[layoutIndex].slots[slotIndex].frame =
                        GridLayoutEngine.normalizedRect(for: gridRect, in: gridSize)
                }
            }
        }

        return LayoutDocument(
            schemaVersion: Self.currentSchemaVersion,
            layouts: layouts
        )
    }

    private func isLegacyFocusGrid(_ layout: WorkspaceLayout) -> Bool {
        layout.name == "Focus + Four"
            && layout.slots.count == 5
            && layout.slots.dropFirst().allSatisfy { $0.frame.width < 0.3 }
    }
}
