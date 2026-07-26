import Foundation

struct ArrangementResult: Equatable, Sendable {
    let arrangedCount: Int
    let requestedCount: Int
    let missingTaskTitles: [String]

    var message: String {
        if requestedCount == 0 {
            return "Assign at least one Codex task before arranging."
        }
        if missingTaskTitles.isEmpty {
            return "Arranged \(arrangedCount) Codex \(arrangedCount == 1 ? "window" : "windows")."
        }
        let names = missingTaskTitles.joined(separator: ", ")
        return "Arranged \(arrangedCount) of \(requestedCount). Open the missing task windows and try again: \(names)."
    }
}
