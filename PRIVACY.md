# Privacy

Codex Layouts is designed to work without a server.

## Data the app reads

The task picker opens `~/.codex/state_5.sqlite` in SQLite read-only mode and
reads the task ID, title, working directory, and update timestamp for recent,
non-archived tasks. It does not read task messages for display or persistence.

The window arranger uses macOS Accessibility to read the titles of open Codex
windows and to set their position and size.

## Data the app stores

Layouts and task assignments are stored in:

`~/Library/Application Support/CodexLayouts/layouts.json`

This file can contain Codex task IDs and titles may appear in the live UI, but
task message content is not written to it.

## Network and analytics

The app contains no networking, analytics, advertising, crash-reporting, or
telemetry SDK. Data is not transmitted by Codex Layouts.

Codex itself is a separate application with its own data practices.

## Removing local data

Quit Codex Layouts and delete:

`~/Library/Application Support/CodexLayouts`

Revoking Accessibility permission in System Settings prevents future window
inspection and movement.
