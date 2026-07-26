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

    init(databaseURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: ".codex/state_5.sqlite")) {
        self.databaseURL = databaseURL
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

        let sql = """
            SELECT id, title, cwd, updated_at_ms
            FROM threads
            WHERE archived = 0
              AND preview <> ''
              AND title <> ''
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

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idText = sqlite3_column_text(statement, 0),
                  let titleText = sqlite3_column_text(statement, 1),
                  let pathText = sqlite3_column_text(statement, 2) else {
                continue
            }

            let milliseconds = sqlite3_column_int64(statement, 3)
            tasks.append(
                CodexTask(
                    id: String(cString: idText),
                    title: String(cString: titleText),
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
}
