# Notify

A native macOS menu bar app for [ntfy](https://ntfy.sh) — a simple HTTP-based pub/sub notification service.

## Features

- **Menu Bar App**: Lives in your menu bar, stays out of your way
- **Real-time Notifications**: Receives messages instantly via Server-Sent Events (SSE)
- **Multiple Topics**: Subscribe to as many topics as you need
- **Custom Servers**: Works with ntfy.sh or your own self-hosted ntfy server
- **Authentication**: Supports username/password auth for protected topics (credentials stored securely in Keychain)
- **Unread Badges**: Shows unread count in the menu bar
- **Native Notifications**: Integrates with macOS notification center with "Mark as Read" action
- **Auto-Reconnect**: Handles network interruptions and sleep/wake gracefully
- **Launch at Login**: Optional startup with your Mac

## Requirements

- macOS 15.0 (Sequoia) or later
- Xcode 16.0 or later (for building)

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/user/ntfyapp.git
   cd ntfyapp
   ```

2. Open the project in Xcode:
   ```bash
   open src/ntfy.xcodeproj
   ```

3. Build and run (Cmd+R)

### Building from Command Line

```bash
xcodebuild -project src/ntfy.xcodeproj -scheme Notify -configuration Release build
```

The built app will be in `build/Release/Notify.app`.

## Usage

1. **Launch the app** — A bell icon appears in your menu bar
2. **Click the bell** → **Show Topics** to open the topics window
3. **Click +** to subscribe to a new topic:
   - Enter the topic name (e.g., `my-alerts`)
   - Optionally change the server URL (defaults to `https://ntfy.sh`)
   - Add credentials if the topic requires authentication
4. **Receive notifications** — Messages appear as macOS notifications and in the app

### Sending Test Notifications

```bash
# Simple notification
curl -d "Hello from ntfy!" ntfy.sh/your-topic-name

# With title and priority
curl -H "Title: Alert" -H "Priority: high" -d "Important message" ntfy.sh/your-topic-name
```

See the [ntfy documentation](https://docs.ntfy.sh/) for more publishing options.

## Project Structure

```
src/
├── ntfy/
│   ├── ntfyApp.swift          # App entry point
│   ├── Models/                # SwiftData models (Topic, Message)
│   ├── Views/                 # SwiftUI views
│   ├── ViewModels/            # AppState
│   └── Services/              # NtfyService, NotificationService, KeychainService
├── ntfyTests/                 # Unit tests
└── ntfyUITests/               # UI tests
```

## License

MIT

## Acknowledgments

- [ntfy](https://ntfy.sh) by Philipp C. Heckel
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) by kishikawakatsumi
