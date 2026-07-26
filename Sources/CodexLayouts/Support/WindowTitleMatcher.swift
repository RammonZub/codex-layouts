import Foundation

struct WindowTitleMatcher {
    static func bestMatchIndex(
        for taskTitle: String,
        in windowTitles: [String]
    ) -> Int? {
        let expected = normalize(taskTitle)
        let candidates = windowTitles.map(normalize)

        if let exactIndex = candidates.firstIndex(of: expected) {
            return exactIndex
        }

        guard expected.count >= 4 else { return nil }
        return candidates.firstIndex { candidate in
            candidate.count >= 4
                && candidate != "codex"
                && candidate != "chatgpt"
                && (
                    candidate.contains(expected)
                        || expected.contains(candidate)
                )
        }
    }

    static func normalize(_ title: String) -> String {
        title
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .replacingOccurrences(of: " — codex", with: "")
            .replacingOccurrences(of: " - codex", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
