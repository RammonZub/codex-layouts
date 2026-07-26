import Foundation

struct CodexTask: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let projectPath: String
    let updatedAt: Date

    var projectName: String {
        let name = URL(fileURLWithPath: projectPath).lastPathComponent
        return name.isEmpty ? "Projectless" : name
    }

    var deepLink: URL? {
        URL(string: "codex://threads/\(id)")
    }
}
