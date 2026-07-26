# Roadmap

## 0.1 — Executable foundation

- [x] Native SwiftUI/AppKit app shell
- [x] Starter layouts and local persistence
- [x] Local Codex task picker
- [x] Display selection
- [x] Accessibility-based window arrangement
- [x] Global shortcut and menu bar access
- [x] Tests, CI, privacy, security, and contributor documentation

## 0.2 — Layout editor

- [x] Cell-based grids with snapping and 1×1 minimum-size constraints
- [x] Continuous drag/resize with live collision reflow
- [x] Shift collisions into the nearest available cells
- [x] In-canvas add and direct card removal
- [x] Select grid densities from 2×2 through 6×4
- [x] Project-grouped task picker with local pins
- [ ] Split and merge selected windows
- [ ] Editable gaps and outer margins
- [ ] Import/export layout JSON
- [ ] Keyboard-only editing

## 0.3 — Reliable task-window orchestration

- [ ] Detect Codex window creation and title changes
- [ ] Reconcile missing, duplicate, and renamed task windows
- [ ] Retry only while an explicit arrange operation is active
- [ ] Replace title matching if Codex exposes a stable public window identity

## 1.0 — Distribution

- [ ] Developer ID signing and hardened runtime
- [ ] Notarized universal release builds
- [ ] Sparkle or another transparent update strategy after dependency review
- [ ] Accessibility, multi-display, and restoration acceptance matrix

The project will not use private APIs or write to Codex's database to accelerate
these milestones.
