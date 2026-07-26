# Contributing

Thank you for helping make multi-task Codex work calmer and faster.

## Before opening a pull request

1. Discuss large product or architecture changes in an issue first.
2. Keep the patch focused and preserve the dependency-free architecture unless
   maintainers explicitly approve a dependency.
3. Do not add private APIs, writes to Codex's database, or background network
   behavior.
4. Run:

   ```sh
   swift test
   ./script/build_and_run.sh --verify
   ```

5. Describe visible behavior, privacy/permission impact, and manual validation.

## Code style

- Prefer small value types and explicit data flow.
- Keep SwiftUI as the source of truth and AppKit bridges narrow.
- Use semantic colors/materials and support Light/Dark mode.
- Maintain 40×40-point interactive hit areas.
- Add tests for layout geometry, persistence, matching, and migrations.

## Issues

Include macOS version, Codex version, display arrangement, reproduction steps,
and expected/actual results. Redact task titles, project paths, and screenshots
that contain private source code.

By participating, you agree to follow the Code of Conduct.
