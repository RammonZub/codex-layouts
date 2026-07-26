# Design system

The interface is a compact macOS utility inspired by Spotlight-sized command
surfaces and by diagrams that show blurred window layers without blurring the
content itself.

## Visual principles

- Frost is a dedicated backdrop layer; content is never blurred together with
  it.
- Layout slots look like miniature Mac windows, including a quiet title bar
  and three neutral traffic-light dots.
- Selection uses a dashed focus ring so geometry stays readable.
- Depth comes from transparent shadows and system materials, not heavy borders.
- Nested radii are concentric: 24-point outer canvas, 16-point inner canvas,
  and 10-point slots with 8-point spacing.
- Interactive controls provide at least a 40×40-point desktop hit area.
- Press feedback uses an interruptible 0.96 scale and respects Reduce Motion.
- Colors and materials are semantic, adapting automatically to Light/Dark mode.

## Reference translation

| Web/reference idea | Native macOS implementation |
| --- | --- |
| Blur a pseudo-layer behind modal content | `NSVisualEffectView` backdrop behind crisp SwiftUI content |
| Dashed modal bounds | Dashed selected-slot overlay that preserves the window silhouette |
| Layered translucent shadows | SwiftUI shadow plus low-opacity neutral ring |
| `scale(0.96)` on press | Reusable `PressScaleButtonStyle` |
| 40-pixel desktop target | 40-point minimum control frames |
| Avoid `transition: all` | Animate only press, hover, and selection state values |
| Web command palette library | Native sheet, menu, keyboard shortcuts, and focus behavior |

## Layout card anatomy

1. Monitor canvas: a quiet material surface with a low-opacity outline.
2. Window slot: separate material, title-bar strip, content label.
3. Slot number: a stable spatial reference for keyboard and voice users.
4. Task label: title plus project name when assigned.
5. Assignment chips: a compact secondary way to revisit a slot.

The layout diagram is the product's main control, not decorative artwork. Each
slot is a real button with an accessibility label and hint.
