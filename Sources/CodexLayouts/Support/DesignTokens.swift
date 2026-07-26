import SwiftUI

enum LayoutDesign {
    static let outerRadius: CGFloat = 24
    static let canvasRadius: CGFloat = 16
    static let slotRadius: CGFloat = 10
    static let cardPadding: CGFloat = 8
    static let slotGap: CGFloat = 8
    static let desktopHitArea: CGFloat = 40

    static let interactiveAnimation = Animation.easeOut(duration: 0.16)
    static let stateAnimation = Animation.easeInOut(duration: 0.22)
    static let layoutSpring = Animation.spring(response: 0.24, dampingFraction: 0.84)
}

extension ShapeStyle where Self == Color {
    static var quietStroke: Color {
        Color.primary.opacity(0.08)
    }
}
