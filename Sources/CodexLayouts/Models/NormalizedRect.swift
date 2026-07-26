import CoreGraphics
import Foundation

struct NormalizedRect: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let unit = NormalizedRect(x: 0, y: 0, width: 1, height: 1)

    var isValid: Bool {
        x >= 0
            && y >= 0
            && width > 0
            && height > 0
            && x + width <= 1.000_001
            && y + height <= 1.000_001
    }

    func appKitFrame(in visibleFrame: CGRect, outerPadding: CGFloat, gap: CGFloat) -> CGRect {
        let canvas = visibleFrame.insetBy(dx: outerPadding, dy: outerPadding)
        let rawFrame = CGRect(
            x: canvas.minX + (canvas.width * x),
            y: canvas.maxY - (canvas.height * (y + height)),
            width: canvas.width * width,
            height: canvas.height * height
        )
        return rawFrame.insetBy(dx: gap / 2, dy: gap / 2).integral
    }
}
