import Foundation
import SQLite3
import Testing
@testable import CodexLayouts

@Suite("Codex conversation discovery")
struct CodexTaskRepositoryTests {
    @Test("Only top-level conversations are returned with their saved titles")
    func excludesInternalThreads() throws {
        let databaseURL = FileManager.default.temporaryDirectory
            .appending(path: "CodexTaskRepositoryTests-\(UUID().uuidString).sqlite")
        let sessionIndexURL = databaseURL.appendingPathExtension("jsonl")
        defer { try? FileManager.default.removeItem(at: databaseURL) }
        defer { try? FileManager.default.removeItem(at: sessionIndexURL) }

        var databasePointer: OpaquePointer?
        #expect(sqlite3_open(databaseURL.path, &databasePointer) == SQLITE_OK)
        let database = try #require(databasePointer)
        defer { sqlite3_close(database) }

        try execute(
            """
            CREATE TABLE threads (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                cwd TEXT NOT NULL,
                updated_at_ms INTEGER NOT NULL,
                recency_at_ms INTEGER NOT NULL,
                archived INTEGER NOT NULL,
                preview TEXT NOT NULL,
                source TEXT NOT NULL,
                thread_source TEXT,
                agent_role TEXT
            );
            """,
            in: database
        )
        try execute(
            """
            INSERT INTO threads VALUES
                ('root', 'Saved conversation title', '/project', 2000, 2000, 0, 'Preview', 'vscode', 'user', NULL),
                ('child', 'Delegated prompt text', '/project', 1900, 1900, 0, 'Preview', 'vscode', 'subagent', NULL),
                ('worker', 'Worker prompt text', '/project', 1800, 1800, 0, 'Preview', 'vscode', 'user', 'worker'),
                ('legacy-child', 'Legacy delegated prompt', '/project', 1700, 1700, 0, 'Preview', '{"thread_spawn":{}}', NULL, NULL);
            """,
            in: database
        )
        try Data(
            """
            {"id":"root","thread_name":"Older saved title","updated_at":"2026-01-01T00:00:00Z"}
            {"id":"root","thread_name":"Actual Codex task title","updated_at":"2026-01-02T00:00:00Z"}

            """.utf8
        )
        .write(to: sessionIndexURL)

        let tasks = try CodexTaskRepository(
            databaseURL: databaseURL,
            sessionIndexURL: sessionIndexURL
        )
        .loadRecentTasks()

        #expect(tasks.map(\.id) == ["root"])
        #expect(tasks.first?.title == "Actual Codex task title")
    }

    private func execute(_ sql: String, in database: OpaquePointer) throws {
        var error: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(database, sql, nil, nil, &error)
        defer { sqlite3_free(error) }
        guard result == SQLITE_OK else {
            let message = error.map { String(cString: $0) } ?? "SQLite error"
            throw RepositoryTestError.sqlite(message)
        }
    }

    private enum RepositoryTestError: Error {
        case sqlite(String)
    }
}
