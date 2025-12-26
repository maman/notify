# URL Scheme Reference

> **Requires:** macOS 14.0 (Sonoma) or later

Notify supports a custom URL scheme that allows you to open topics directly from links, scripts, or other applications.

**Related:** [Siri & Shortcuts](siri-shortcuts.md) · [Focus Mode Integration](focus-mode.md) · [MDM Configuration](mdm-configuration.md)

## URL Format

```
ntfy://<topic-name>
```

### Examples

```
ntfy://my-alerts
ntfy://server-status
ntfy://deploy-notifications
ntfy://FFszGLa9wgFEOd6a
```

## How It Works

When you open an `ntfy://` URL:

1. **If subscribed:** Notify opens and selects the matching topic
2. **If not subscribed:** Notify opens the subscription form with the topic name pre-filled, allowing you to quickly subscribe

## Use Cases

### Create Clickable Links in Documentation

Add links to your internal documentation that open directly in Notify:

```markdown
Monitor deployment status: [Open in Notify](ntfy://deploy-status)
```

### Open Topics from Terminal

```bash
# macOS
open "ntfy://my-alerts"

# Alternative using AppleScript
osascript -e 'open location "ntfy://my-alerts"'
```

### Link from Notification Actions

When configuring ntfy notifications with action buttons, you can use the URL scheme:

```bash
curl -H "Actions: view, Open Topic, ntfy://my-alerts" \
     -d "Check the dashboard" \
     ntfy.sh/my-alerts
```

### Integration with Raycast / Alfred

Create a custom workflow that opens a specific topic:

```bash
# Raycast script command
#!/bin/bash

# @raycast.title Open Alerts
# @raycast.mode silent

open "ntfy://my-alerts"
```

### Shortcuts Automation

In the Shortcuts app, use the "Open URLs" action with an `ntfy://` URL to open a specific topic as part of a workflow.

## Valid Topic Names

Topic names in URLs follow the same rules as ntfy topics:

- Alphanumeric characters (a-z, A-Z, 0-9)
- Hyphens (-) and underscores (_)
- Case-sensitive (`MyTopic` ≠ `mytopic`)

### Valid Examples

```
ntfy://simple
ntfy://with-hyphens
ntfy://with_underscores
ntfy://MixedCase123
ntfy://FFszGLa9wgFEOd6a
```

### Invalid Examples

```
ntfy://             # Empty topic name
ntfy://has spaces   # Spaces not allowed
ntfy://special!@#   # Special characters not allowed
```

## Registering the URL Scheme

Notify automatically registers the `ntfy://` URL scheme when installed. No additional configuration is required.

If another application has registered the same scheme, macOS will prompt you to choose which app should handle the URL.

## Combining with ntfy Web Links

If you want links that work in both browsers and Notify, consider providing both options:

```html
<p>
  View alerts:
  <a href="https://ntfy.sh/my-alerts">Web</a> |
  <a href="ntfy://my-alerts">Notify App</a>
</p>
```

## Troubleshooting

### URL Not Opening Notify

1. **Verify Notify is installed** — The app must be in your Applications folder
2. **Check the URL format** — Ensure the topic name is valid (no spaces or special characters)
3. **Verify registration** — Run `open ntfy://test` in Terminal to test

### Topic Not Found

If the topic doesn't exist in your subscriptions, Notify will open the subscription form with the topic name pre-filled. Simply configure any additional settings (server URL, authentication) and click Subscribe.

### Conflicts with Other Apps

If another app has registered the `ntfy://` scheme:

1. Open **Finder** → **Applications**
2. Right-click **Notify** → **Get Info**
3. Check "Open with" shows Notify as the default

## API Reference

### URL Components

| Component | Value | Description |
|-----------|-------|-------------|
| Scheme | `ntfy` | The URL scheme identifier |
| Host | Topic name | The ntfy topic to open |
