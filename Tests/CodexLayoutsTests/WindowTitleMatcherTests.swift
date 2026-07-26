import Testing
@testable import CodexLayouts

@Suite("Codex window title matching")
struct WindowTitleMatcherTests {
    @Test("Exact task title is preferred")
    func exactTitleWins() {
        let index = WindowTitleMatcher.bestMatchIndex(
            for: "Build the layout editor",
            in: [
                "Build the layout editor — Codex",
                "Build the layout editor follow-up — Codex"
            ]
        )

        #expect(index == 0)
    }

    @Test("Codex title suffix and letter case are ignored")
    func suffixAndCaseAreIgnored() {
        let index = WindowTitleMatcher.bestMatchIndex(
            for: "Set Up Codex Chat Layouts",
            in: ["set up codex chat layouts — CODEX"]
        )

        #expect(index == 0)
    }

    @Test("A generic app window is never treated as a task")
    func genericWindowIsIgnored() {
        let index = WindowTitleMatcher.bestMatchIndex(
            for: "Improve Codex navigation",
            in: ["Codex"]
        )

        #expect(index == nil)
    }

    @Test("Short titles require an exact match")
    func shortTitlesRequireExactMatch() {
        let index = WindowTitleMatcher.bestMatchIndex(
            for: "UI",
            in: ["UI review — Codex"]
        )

        #expect(index == nil)
    }
}
