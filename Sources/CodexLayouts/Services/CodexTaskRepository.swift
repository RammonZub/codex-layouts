import Foundation
import SQLite3

struct CodexTaskRepository {
    enum RepositoryError: LocalizedError {
        case databaseNotFound(String)
        case openFailed(String)
        case queryFailed(String)

        var errorDescription: String? {
            switch self {
            case .databaseNotFound(let path):
                "Codex task history was not found at \(path)."
            case .openFailed(let message):
                "Codex task history could not be opened: \(message)"
            case .queryFailed(let message):
                "Codex tasks could not be read: \(message)"
            }
        }
    }

    let databaseURL: URL
    let sessionIndexURL: URL

    init(
        databaseURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".codex/state_5.sqlite"),
        sessionIndexURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".codex/session_index.jsonl")
    ) {
        self.databaseURL = databaseURL
        self.sessionIndexURL = sessionIndexURL
    }

    func loadRecentTasks(limit: Int = 250) throws -> [CodexTask] {
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            throw RepositoryError.databaseNotFound(databaseURL.path)
        }

        var database: OpaquePointer?
        let openResult = sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX,
            nil
        )
        guard openResult == SQLITE_OK, let database else {
            let message = database.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error."
            if let database {
                sqlite3_close(database)
            }
            throw RepositoryError.openFailed(message)
        }
        defer { sqlite3_close(database) }

        let columns = try columnNames(in: database)
        var filters = [
            "archived = 0",
            "preview <> ''",
            "title <> ''"
        ]
        if columns.contains("thread_source") {
            filters.append("(thread_source IS NULL OR thread_source <> 'subagent')")
        }
        if columns.contains("agent_role") {
            filters.append("(agent_role IS NULL OR agent_role = '')")
        }
        if columns.contains("source") {
            filters.append("source NOT LIKE '%\"thread_spawn\"%'")
        }

        let sql = """
            SELECT id, title, cwd, updated_at_ms
            FROM threads
            WHERE \(filters.joined(separator: "\n              AND "))
            ORDER BY recency_at_ms DESC, id DESC
            LIMIT ?;
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw RepositoryError.queryFailed(String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, Int32(max(1, limit)))
        var tasks: [CodexTask] = []
        let savedTitles = loadSavedTitles()

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idText = sqlite3_column_text(statement, 0),
                  let titleText = sqlite3_column_text(statement, 1),
                  let pathText = sqlite3_column_text(statement, 2) else {
                continue
            }

            let milliseconds = sqlite3_column_int64(statement, 3)
            let id = String(cString: idText)
            let databaseTitle = String(cString: titleText)
            tasks.append(
                CodexTask(
                    id: id,
                    title: savedTitles[id] ?? databaseTitle,
                    projectPath: String(cString: pathText),
                    updatedAt: Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1_000)
                )
            )
        }

        let finalResult = sqlite3_errcode(database)
        guard finalResult == SQLITE_OK || finalResult == SQLITE_DONE else {
            throw RepositoryError.queryFailed(String(cString: sqlite3_errmsg(database)))
        }
        return tasks
    }

    private func loadSavedTitles() -> [String: String] {
        struct SessionIndexEntry: Decodable {
            let id: String
            let threadName: String

            private enum CodingKeys: String, CodingKey {
                case id
                case threadName = "thread_name"
            }
        }

        guard let data = try? Data(contentsOf: sessionIndexURL),
              let contents = String(data: data, encoding: .utf8) else {
            return [:]
        }

        let decoder = JSONDecoder()
        var titles: [String: String] = [:]
        for line in contents.split(whereSeparator: \.isNewline) {
            let lineData = Data(line.utf8)
            guard let entry = try? decoder.decode(SessionIndexEntry.self, from: lineData) else {
                continue
            }
            let title = entry.threadName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty {
                titles[entry.id] = title
            }
        }
        return titles
    }

    private func columnNames(in database: OpaquePointer) throws -> Set<String> {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(
            database,
            "PRAGMA table_info(threads);",
            -1,
            &statement,
            nil
        ) == SQLITE_OK,
        let statement else {
            throw RepositoryError.queryFailed(String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }

        var names = Set<String>()
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let nameText = sqlite3_column_text(statement, 1) else {
                continue
            }
            names.insert(String(cString: nameText))
        }
        return names
    }
}
