# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the app
xcodebuild -project src/ntfy.xcodeproj -scheme Notify -configuration Debug build

# Run unit tests
xcodebuild -project src/ntfy.xcodeproj -scheme Notify test

# Run a specific test
xcodebuild -project src/ntfy.xcodeproj -scheme Notify -only-testing:ntfyTests/ntfyTests/testName test

# Run UI tests
xcodebuild -project src/ntfy.xcodeproj -scheme ntfyUITests test

# Clean build
xcodebuild -project src/ntfy.xcodeproj -scheme Notify clean
```

Alternatively, open `src/ntfy.xcodeproj` in Xcode and use Cmd+B to build, Cmd+U to test.

## Architecture

**Notify** is a macOS menu bar app (LSUIElement) for receiving push notifications from ntfy.sh servers via Server-Sent Events (SSE).

### Core Components

- **ntfyApp.swift**: App entry point with two scenes - a `MenuBarExtra` for the menu bar icon and a `Window` for topic management. Uses SwiftData `ModelContainer` shared across views.

- **AppState** (`ViewModels/AppState.swift`): Central `@Observable` state container holding:

  - `NtfyService` for SSE connections
  - `NotificationService` for system notifications
  - `KeychainService` for credential storage
  - Topic/message CRUD operations
  - Dock visibility control (shows dock icon only when window is open)

- **NtfyService** (`Services/NtfyService.swift`): Two-layer architecture:
  - `NtfyServiceActor`: Swift actor handling SSE streaming, reconnection with exponential backoff, and message parsing
  - `NtfyService`: `@Observable` wrapper exposing per-topic `TopicConnectionState` objects to prevent cascading view updates
  - Handles sleep/wake reconnection automatically

### Data Models (SwiftData)

- **Topic**: Subscription with name, server URL, optional auth (username stored in model, password in Keychain)
- **Message**: Received notification with title, body, priority, tags, actions, read status. Cascade-deleted with topic.

### Key Patterns

- Uses Swift 6 concurrency with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- Topic selection uses `UUID` instead of full `Topic` object to minimize view invalidation
- Password storage: username in SwiftData, password in Keychain keyed by topic UUID
- Notifications use `UNUserNotificationCenter` with custom categories for "Mark as Read" action

### Dependencies

- **KeychainAccess** (4.2.2): Keychain wrapper for credential storage

## ntfy Documentation

Reference documentation for the ntfy service is available in the `docs/` directory:

- **[docs/ntfy-api.md](docs/ntfy-api.md)**: Complete ntfy API reference including message format, SSE subscription, publishing headers, action buttons, attachments, authentication, and rate limits

## External Resources

To read files in GitHub repos use https://gitchamber.com. Always run `curl -s https://gitchamber.com` first to see usage instructions.
