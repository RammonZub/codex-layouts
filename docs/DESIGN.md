# Design system

The interface is a compact macOS utility inspired by Spotlight-sized command
surfaces and by diagrams that show blurred window layers without blurring the
content itself.

## Visual principles

- Frost is a dedicated backdrop layer; content is never blurred together with
  it.
- Layout slots look like miniature Mac windows, including a quiet title bar
  and three neutral traffic-light dots.
- Selection uses a precise accent ring and a visible corner resize handle.
- Dashed grid lines make 1×1 units legible without overpowering the windows.
- Dragged and resized windows follow the pointer continuously, preview their
  snapped cell, and reflow collisions before the pointer is released.
- The first open 1×1 cell becomes an in-canvas Add target. Selection reveals a
  close control and a large corner resize handle on the card itself.
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
| Dashed modal bounds | Quiet grid guides behind crisp window silhouettes |
| Layered translucent shadows | SwiftUI shadow plus low-opacity neutral ring |
| `scale(0.96)` on press | Reusable `PressScaleButtonStyle` |
| 40-pixel desktop target | 40-point minimum control frames |
| Avoid `transition: all` | Animate only press, hover, and selection state values |
| Web command palette library | Native sheet, menu, keyboard shortcuts, and focus behavior |

## Layout card anatomy

1. Monitor canvas: a quiet material surface with a low-opacity outline.
2. Window slot: separate material, title-bar strip, content label.
3. Grid-size badge: the window's current column and row span.
4. Slot number: a stable spatial reference for keyboard and voice users.
5. Task label: the saved Codex task title plus project name when space allows.
6. Resize handle: a direct manipulation affordance on the selected window.

The layout diagram is the product's main control, not decorative artwork. The
card body and title-bar handle drag, the corner handle resizes, and a
double-click on the body opens the conversation picker. Decorative material and
stroke layers are always click-through. The picker separates pinned tasks from
project folders and never displays internal subagent threads.
