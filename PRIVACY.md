# Privacy

Codex Layouts is designed to work without a server.

## Data the app reads

The task picker opens `~/.codex/state_5.sqlite` in SQLite read-only mode and
reads the task ID, saved title, working directory, and update timestamp for
recent, non-archived, top-level tasks. Internal subagent and worker rows are
filtered out. It does not read task messages for display or persistence.

The picker also reads `~/.codex/session_index.jsonl` to use Codex's saved,
human-friendly task names instead of first-message fallback text.

The layout canvas asks macOS for the selected display's desktop-image URL and
renders that image locally as a preview background. The image is not copied,
stored, or transmitted.

The window arranger uses macOS Accessibility to read the titles of open Codex
windows and to set their position and size.

## Data the app stores

Layouts and task assignments are stored in:

`~/Library/Application Support/CodexLayouts/layouts.json`

This file can contain Codex task IDs and titles may appear in the live UI, but
task message content is not written to it.

Task IDs pinned inside Codex Layouts are stored in the app's local preferences.
These pins are independent from Codex's own sidebar pins.

## Network and analytics

The app contains no networking, analytics, advertising, crash-reporting, or
telemetry SDK. Data is not transmitted by Codex Layouts.

Codex itself is a separate application with its own data practices.

## Removing local data

Quit Codex Layouts and delete:

`~/Library/Application Support/CodexLayouts`

Revoking Accessibility permission in System Settings prevents future window
inspection and movement.
