import SwiftUI

struct PressScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed && !reduceMotion ? 0.96 : 1
            )
            .animation(
                reduceMotion ? nil : LayoutDesign.interactiveAnimation,
                value: configuration.isPressed
            )
    }
}
