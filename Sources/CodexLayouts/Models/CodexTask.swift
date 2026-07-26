import Foundation

struct CodexTask: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let projectPath: String
    let updatedAt: Date

    var projectID: String {
        URL(fileURLWithPath: projectPath).standardizedFileURL.path
    }

    var projectName: String {
        let name = URL(fileURLWithPath: projectPath).lastPathComponent
        return name.isEmpty ? "Projectless" : name
    }

    var deepLink: URL? {
        URL(string: "codex://threads/\(id)")
    }
}

struct CodexProjectGroup: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let path: String
    let tasks: [CodexTask]

    var mostRecentUpdate: Date {
        tasks.map(\.updatedAt).max() ?? .distantPast
    }
}
