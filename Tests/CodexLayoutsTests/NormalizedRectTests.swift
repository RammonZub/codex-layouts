import CoreGraphics
import Testing
@testable import CodexLayouts

@Suite("Normalized layout geometry")
struct NormalizedRectTests {
    @Test("Top-left normalized coordinates convert to AppKit coordinates")
    func convertsTopLeftCoordinates() {
        let rect = NormalizedRect(x: 0, y: 0, width: 0.5, height: 0.5)
        let frame = rect.appKitFrame(
            in: CGRect(x: 0, y: 0, width: 1_000, height: 800),
            outerPadding: 0,
            gap: 0
        )

        #expect(frame == CGRect(x: 0, y: 400, width: 500, height: 400))
    }

    @Test("Padding and gaps stay inside the visible frame")
    func appliesPaddingAndGap() {
        let frame = NormalizedRect.unit.appKitFrame(
            in: CGRect(x: -2_304, y: 0, width: 2_304, height: 1_260),
            outerPadding: 6,
            gap: 8
        )

        #expect(frame.minX >= -2_304)
        #expect(frame.minY >= 0)
        #expect(frame.maxX <= 0)
        #expect(frame.maxY <= 1_260)
    }

    @Test("Every starter slot is valid and contained")
    func startersAreValid() {
        for layout in WorkspaceLayout.starters {
            #expect(!layout.slots.isEmpty)
            let allFramesAreValid = layout.slots.allSatisfy { slot in
                slot.frame.isValid
            }
            #expect(allFramesAreValid)
        }
    }
}
