import Testing
@testable import CodexLayouts

@Suite("Grid interaction ownership")
struct GridInteractionStateTests {
    @Test("Move and resize cannot own the same card simultaneously")
    func interactionsAreExclusive() {
        let origin = GridRect(
            column: 0,
            row: 0,
            columnSpan: 2,
            rowSpan: 1
        )
        var interaction = GridInteractionState()

        #expect(interaction.begin(.move, at: origin) == origin)
        #expect(interaction.begin(.resize, at: origin) == nil)
        #expect(interaction.activeKind == .move)

        interaction.end(.resize)
        #expect(interaction.activeKind == .move)

        interaction.end(.move)
        #expect(interaction.activeKind == nil)
    }

    @Test("Resize ownership blocks movement until resizing ends")
    func resizeBlocksMove() {
        let origin = GridRect(
            column: 1,
            row: 0,
            columnSpan: 1,
            rowSpan: 2
        )
        var interaction = GridInteractionState()

        #expect(interaction.begin(.resize, at: origin) == origin)
        #expect(interaction.begin(.move, at: origin) == nil)

        interaction.end(.resize)
        #expect(interaction.begin(.move, at: origin) == origin)
    }
}
