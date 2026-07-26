# Architecture

Codex Layouts is a native Swift 6 macOS application built as a Swift package.
The package has no third-party runtime dependencies and can be opened directly
in Xcode.

## Boundaries

- `App/` owns scenes, app lifecycle, commands, and activation.
- `Views/` owns SwiftUI composition and view-local interaction state.
- `Models/` contains Codable value types, discrete grid geometry, and normalized
  display geometry.
- `Stores/` owns app state and local JSON persistence.
- `Services/` is the narrow platform boundary for SQLite, Accessibility,
  deep links, and the global hotkey.
- `Support/` contains reusable visual and activation glue.

SwiftUI is the source of truth. AppKit is limited to the frosted backdrop,
workspace activation, and display metadata. ApplicationServices is isolated in
the window arranger and permission helper.

## Data flow

```mermaid
flowchart LR
    DB["Codex state_5.sqlite<br/>read-only"] --> Filter["Top-level conversation filter"]
    Titles["session_index.jsonl<br/>friendly titles"] --> Filter
    Filter --> Picker["Pinned + project picker"]
    JSON["Application Support<br/>layouts.json"] <--> Model["AppModel"]
    Picker --> Model
    Model --> Grid["Snap + collision reflow"]
    Grid --> Preview["Grid editor"]
    Model --> Arranger["WindowArranger"]
    Screen["NSScreen visibleFrame"] --> Arranger
    Arranger --> AX["macOS Accessibility"]
    AX --> Codex["Open Codex windows"]
```

## Privacy invariants

- The Codex SQLite database is opened with `SQLITE_OPEN_READONLY`.
- `session_index.jsonl` is read only to resolve the same friendly titles shown
  in the Codex sidebar.
- Queries are bounded to 250 rows.
- Subagent, worker, and thread-spawn records are filtered before display.
- The app has no networking code.
- Layout persistence contains task IDs and layout metadata, not messages.
- Accessibility access is not requested until the user asks for it.

## Coordinate systems

The editor uses integer `GridRect` values so a 1×1 cell is the smallest unit.
Every accepted move and resize is clamped to the selected grid. When a proposed
window overlaps another, the grid engine moves the displaced window to its
nearest available position; it rejects the edit if every valid position is
occupied.

Persisted slots retain a top-left normalized rectangle (`0...1`) for stable
cross-display arrangement. The solver converts that rectangle into AppKit's
bottom-left screen coordinates, then the Accessibility edge converts positions
to the global top-left coordinate space.

Display frames always come from `NSScreen.visibleFrame`, so the menu bar and
Dock are respected and no monitor resolution is hard-coded.

## Known compatibility seam

Codex does not currently expose a stable public API that maps a task ID to a
specific native window. The first release therefore matches open windows by
their visible task title. This implementation is isolated inside
`WindowArranger` so a future official window identity API can replace it
without changing the layout model or UI.
