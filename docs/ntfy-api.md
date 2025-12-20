# ntfy API Reference

This document provides a complete reference for the ntfy API, which this macOS app uses to receive push notifications.

## Overview

ntfy (pronounced "notify") is a simple HTTP-based pub-sub notification service. Messages are published to topics via HTTP POST/PUT and received via Server-Sent Events (SSE), WebSocket, or polling.

- **Public server**: `https://ntfy.sh`
- **Self-hosted**: Any ntfy server instance

> **Security Note**: Topic names are public. Choose names that cannot be easily guessed.

## Subscribing to Topics

### SSE Stream (Used by this app)

The app uses Server-Sent Events for efficient, real-time message streaming:

```
GET /<topic>/sse
```

**Example**:
```bash
curl -s ntfy.sh/mytopic/sse
```

**Response format**:
```
event: open
data: {"id":"...","time":1234567890,"event":"open","topic":"mytopic"}

event: message
data: {"id":"abc123","time":1234567890,"event":"message","topic":"mytopic","message":"Hello!","title":"Greeting","priority":3,"tags":["wave"]}

event: keepalive
data: {"id":"...","time":1234567890,"event":"keepalive","topic":"mytopic"}
```

### Other Subscription Methods

| Endpoint | Format | Use Case |
|----------|--------|----------|
| `/<topic>/json` | Newline-delimited JSON | Most programming languages |
| `/<topic>/sse` | Server-Sent Events | JavaScript EventSource, real-time apps |
| `/<topic>/ws` | WebSocket | Bidirectional communication |
| `/<topic>/raw` | Plain text (message body only) | Simple scripts |

### Query Parameters

| Parameter | Description |
|-----------|-------------|
| `poll=1` | Return cached messages and close (no streaming) |
| `since=<duration/timestamp/id>` | Fetch messages since time (e.g., `10m`, `1639194738`, `latest`) |
| `scheduled=1` | Include messages scheduled for future delivery |

### Multi-topic Subscription

Subscribe to multiple topics with comma separation:
```bash
curl -s "ntfy.sh/topic1,topic2,topic3/sse"
```

## Message Format

### JSON Message Structure

```json
{
  "id": "sPs7YANab",
  "time": 1703012345,
  "expires": 1703098745,
  "event": "message",
  "topic": "mytopic",
  "message": "Backup complete",
  "title": "Server Alert",
  "priority": 4,
  "tags": ["heavy_check_mark", "backup"],
  "click": "https://example.com/status",
  "actions": [
    {
      "action": "view",
      "label": "Open Dashboard",
      "url": "https://example.com/dashboard",
      "clear": true
    }
  ],
  "attachment": {
    "name": "log.txt",
    "url": "https://ntfy.sh/file/abc123.txt",
    "type": "text/plain",
    "size": 1024,
    "expires": 1703098745
  }
}
```

### Event Types

| Event | Description |
|-------|-------------|
| `open` | Connection established |
| `message` | New notification message |
| `keepalive` | Connection heartbeat (no action needed) |
| `poll_request` | Server requesting client poll |

### Priority Levels

| Value | Name | Behavior |
|-------|------|----------|
| 5 | `max` / `urgent` | Long vibration, pop-over notification |
| 4 | `high` | Long vibration, pop-over notification |
| 3 | `default` | Standard notification |
| 2 | `low` | No vibration/sound |
| 1 | `min` | Minimal, hidden under fold |

### Tags and Emojis

Tags matching emoji short codes are rendered as emojis:

| Tag | Emoji |
|-----|-------|
| `warning` | Warning |
| `rotating_light` | Rotating light |
| `heavy_check_mark` | Check mark |
| `x` | X mark |
| `skull` | Skull |
| `tada` | Celebration |
| `rocket` | Rocket |
| `fire` | Fire |

Full list: https://docs.ntfy.sh/emojis/

## Publishing Messages

### Basic Publishing

```bash
# Simple message
curl -d "Hello World" ntfy.sh/mytopic

# With title
curl -H "Title: Alert" -d "Something happened" ntfy.sh/mytopic

# With priority
curl -H "Priority: urgent" -d "Critical error!" ntfy.sh/mytopic

# With tags
curl -H "Tags: warning,server" -d "Disk space low" ntfy.sh/mytopic
```

### JSON Publishing

```bash
curl ntfy.sh -d '{
  "topic": "mytopic",
  "message": "Disk space low on server1",
  "title": "Warning",
  "priority": 4,
  "tags": ["warning", "disk"],
  "click": "https://example.com/dashboard",
  "actions": [{
    "action": "view",
    "label": "View Dashboard",
    "url": "https://example.com/dashboard"
  }]
}'
```

### All Publishing Headers

| Header | Aliases | Description |
|--------|---------|-------------|
| `X-Message` | `m` | Message body (alternative to request body) |
| `X-Title` | `t`, `Title` | Notification title |
| `X-Priority` | `p`, `prio`, `Priority` | Priority level (1-5 or name) |
| `X-Tags` | `ta`, `tag`, `Tags` | Comma-separated tags |
| `X-Click` | `Click` | URL to open on notification tap |
| `X-Actions` | `Actions` | Action buttons (see below) |
| `X-Attach` | `a`, `Attach` | URL of file to attach |
| `X-Filename` | `f`, `Filename` | Filename for attachment |
| `X-Icon` | `Icon` | URL of notification icon |
| `X-Delay` | `At`, `In`, `Delay` | Scheduled delivery time |
| `X-Email` | `e`, `Email` | Email address for forwarding |
| `X-Call` | `Call` | Phone number for voice call |
| `X-Markdown` | `md`, `Markdown` | Enable markdown (`yes`/`1`) |
| `X-Cache` | `Cache` | Disable caching (`no`) |
| `X-Firebase` | `Firebase` | Disable FCM (`no`) |

## Action Buttons

Messages can include up to 3 action buttons.

### View Action

Opens a URL when tapped:
```bash
curl -H "Actions: view, Open Site, https://example.com, clear=true" \
     -d "Check this out" ntfy.sh/mytopic
```

JSON format:
```json
{
  "action": "view",
  "label": "Open Site",
  "url": "https://example.com",
  "clear": true
}
```

### HTTP Action

Sends an HTTP request:
```bash
curl -H "Actions: http, Turn Off, https://api.home/lights, method=POST, body={\"state\":\"off\"}" \
     -d "Lights are on" ntfy.sh/mytopic
```

JSON format:
```json
{
  "action": "http",
  "label": "Turn Off",
  "url": "https://api.home/lights",
  "method": "POST",
  "headers": {"Authorization": "Bearer token"},
  "body": "{\"state\":\"off\"}",
  "clear": true
}
```

### Broadcast Action (Android only)

Sends an Android broadcast intent:
```json
{
  "action": "broadcast",
  "label": "Take Photo",
  "intent": "io.heckel.ntfy.USER_ACTION",
  "extras": {"cmd": "photo", "camera": "front"}
}
```

## Attachments

### Upload File

```bash
curl -T report.pdf -H "Filename: report.pdf" ntfy.sh/mytopic
```

Limits: 15 MB max per file, files expire after 3 hours.

### External URL

```bash
curl -H "Attach: https://example.com/image.jpg" \
     -d "See attached" ntfy.sh/mytopic
```

## Authentication

### Basic Auth

```bash
curl -u username:password \
     -d "Secret message" https://ntfy.example.com/private-topic
```

### Bearer Token

```bash
curl -H "Authorization: Bearer tk_abc123..." \
     -d "Secret message" https://ntfy.example.com/private-topic
```

### Query Parameter

Base64-encode the Authorization header value:
```bash
curl "https://ntfy.example.com/topic?auth=QmFzaWMgdXNlcjpwYXNz"
```

## Scheduled Delivery

Delay message delivery:

```bash
# Natural language
curl -H "Delay: tomorrow, 10am" -d "Good morning" ntfy.sh/topic

# Duration
curl -H "In: 30m" -d "Reminder" ntfy.sh/topic

# Unix timestamp
curl -H "At: 1639194738" -d "Scheduled" ntfy.sh/topic
```

Limits: Minimum 10 seconds, maximum 3 days.

## Rate Limits (ntfy.sh)

| Resource | Limit |
|----------|-------|
| Messages | 250/day per topic |
| Emails | 16 initial, then 1/hour |
| Attachments | 15 MB per file, 100 MB total |
| Attachment expiry | 3 hours |
| Scheduled messages | 3 days max delay |

## Error Responses

| Status | Meaning |
|--------|---------|
| 400 | Bad request (invalid parameters) |
| 401 | Unauthorized (authentication required) |
| 403 | Forbidden (access denied) |
| 404 | Topic not found |
| 413 | Payload too large |
| 429 | Too many requests (rate limited) |
| 500 | Internal server error |

## References

- Official documentation: https://docs.ntfy.sh
- Publishing guide: https://docs.ntfy.sh/publish/
- Subscribe API: https://docs.ntfy.sh/subscribe/api/
- Emoji list: https://docs.ntfy.sh/emojis/
