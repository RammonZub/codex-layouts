import Foundation
import Testing
@testable import CodexLayouts

@Suite("Layout switcher selection")
struct LayoutSwitcherSelectionTests {
    @Test("Selection moves in both directions and wraps")
    func selectionWraps() {
        let ids = [UUID(), UUID(), UUID()]
        var selection = LayoutSwitcherSelection(
            layoutIDs: ids,
            selectedID: ids[0]
        )

        selection.move(by: -1)
        #expect(selection.selectedID == ids[2])

        selection.move(by: 1)
        #expect(selection.selectedID == ids[0])
    }

    @Test("Missing selection starts on the first layout")
    func missingSelectionUsesFirstLayout() {
        let ids = [UUID(), UUID()]
        let selection = LayoutSwitcherSelection(
            layoutIDs: ids,
            selectedID: UUID()
        )

        #expect(selection.selectedID == ids[0])
    }
}
