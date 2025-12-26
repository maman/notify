# Siri & Shortcuts Integration

> **Requires:** macOS 14.0 (Sonoma) or later

Notify integrates with Siri and the Shortcuts app, allowing you to control notifications with voice commands and build powerful automations.

**Related:** [Focus Mode Integration](focus-mode.md) · [URL Scheme Reference](url-scheme.md) · [MDM Configuration](mdm-configuration.md)

## Siri Voice Commands

Notify registers pre-configured Siri phrases that work out of the box. Just say:

| Command                                  | What it does                  |
| ---------------------------------------- | ----------------------------- |
| "Hey Siri, how many unread in Notify"    | Get total unread count        |
| "Hey Siri, check Notify notifications"   | Get unread notification count |
| "Hey Siri, mark all Notify as read"      | Mark all messages as read     |
| "Hey Siri, clear Notify notifications"   | Mark all messages as read     |
| "Hey Siri, subscribe to topic in Notify" | Subscribe to a new topic      |
| "Hey Siri, add topic to Notify"          | Subscribe to a new topic      |
| "Hey Siri, open [topic] in Notify"       | Open a specific topic         |

### Tips for Voice Commands

- Speak the topic name clearly when using "Open [topic] in Notify"
- Siri will confirm the action and show the result
- If Siri doesn't recognize "Notify", try "N T F Y" or add Notify to your vocabulary in System Settings

## Shortcuts App Actions

Notify provides six actions in the Shortcuts app for building custom automations:

### Get Unread Count

Returns the number of unread messages.

| Parameter | Required | Description                                                          |
| --------- | -------- | -------------------------------------------------------------------- |
| Topic     | No       | Specific topic to count. If omitted, returns total across all topics |

**Returns:** Integer count

**Example uses:**

- Display unread count in a widget
- Trigger alerts when count exceeds threshold
- Log notification volumes over time

### Mark All Messages as Read

Marks all messages in a topic as read.

| Parameter | Required | Description               |
| --------- | -------- | ------------------------- |
| Topic     | Yes      | The topic to mark as read |

**Returns:** Number of messages marked

**Example uses:**

- Clear notifications at end of workday
- Reset a topic after reviewing on another device

### Mark Message as Read

Marks a single message as read.

| Parameter | Required | Description                  |
| --------- | -------- | ---------------------------- |
| Message   | Yes      | The specific message to mark |

**Returns:** Confirmation

**Example uses:**

- Chain with "Get Messages" to process messages programmatically

### Subscribe to Topic

Subscribes to a new ntfy topic.

| Parameter  | Required | Default           | Description                    |
| ---------- | -------- | ----------------- | ------------------------------ |
| Topic Name | Yes      | —                 | The topic name to subscribe to |
| Server URL | No       | `https://ntfy.sh` | The ntfy server URL            |

**Returns:** The created topic entity

**Example uses:**

- Subscribe to event-specific topics automatically
- Set up temporary topics for projects

### Unsubscribe from Topic

Removes a topic subscription.

| Parameter | Required | Description                            |
| --------- | -------- | -------------------------------------- |
| Topics    | Yes      | One or more topics to unsubscribe from |

**Returns:** Number of topics removed

**Notes:**

- MDM-managed topics cannot be unsubscribed and will be skipped
- Removing a topic deletes all its messages

### Open Topic

Opens Notify and navigates to a specific topic.

| Parameter | Required | Description       |
| --------- | -------- | ----------------- |
| Topic     | Yes      | The topic to open |

**Returns:** Confirmation dialog

**Example uses:**

- Quick access buttons for important topics
- Deep link from other automations

## Building Shortcuts

### Example: Daily Digest

Create a shortcut that shows your unread count each morning:

1. Open the **Shortcuts** app
2. Click **+** to create a new shortcut
3. Add **Get Unread Count** (from Notify)
4. Add **Show Notification** with the count
5. Set up an automation trigger for 8:00 AM

### Example: Topic Quick Actions

Create shortcuts for frequently-used topics:

1. Create a new shortcut
2. Add **Open Topic**
3. Select your topic (e.g., "production-alerts")
4. Save as "Open Production Alerts"
5. Add to Dock or assign a keyboard shortcut

### Example: Cleanup Automation

Automatically clear old notifications:

1. Create a new shortcut
2. Add **Get Unread Count** for your topic
3. Add **If** (count > 100)
4. Add **Mark All Messages as Read**
5. Schedule to run weekly

## Automation Triggers

Combine Notify actions with Shortcuts automation triggers:

| Trigger                   | Example Use                                   |
| ------------------------- | --------------------------------------------- |
| **Time of Day**           | Clear notifications at 6 PM                   |
| **Arrive/Leave Location** | Subscribe to location-specific topics         |
| **Focus Mode**            | Switch topic priorities based on Focus        |
| **App Open/Close**        | Check notifications when opening related apps |
| **Shortcut Input**        | Process topic names from other apps           |

## Widgets

Use Shortcuts widgets to display Notify information on your desktop:

1. Create a shortcut that uses **Get Unread Count**
2. Add a **Show Result** action
3. Right-click desktop → Edit Widgets
4. Add a Shortcuts widget
5. Configure it to run your shortcut

## Troubleshooting

### Siri Doesn't Recognize Commands

1. **Verify Siri is enabled** — System Settings → Siri
2. **Check Notify is indexed** — Quit and reopen Notify to re-register shortcuts
3. **Try alternative phrases** — See the voice commands table above
4. **Reset Siri** — System Settings → Siri → Siri History → Delete Siri History

### Actions Not Appearing in Shortcuts

1. **Restart Notify** — Quit and reopen the app
2. **Check macOS version** — App Intents require macOS 14.0+
3. **Search correctly** — Search for "Notify" or the action name in Shortcuts

### Actions Return Errors

1. **Topic not found** — Ensure the topic exists in your subscriptions
2. **Message not found** — The message may have been deleted
3. **MDM restriction** — Cannot unsubscribe from managed topics

### Automation Not Running

1. **Check permissions** — System Settings → Privacy → Automation
2. **Verify trigger** — Test the automation manually first
3. **Review conditions** — Ensure all If/Otherwise conditions are correct

## Privacy Notes

- Shortcuts actions run locally on your Mac
- No data is sent to Apple or third parties through Shortcuts
- Topic and message content stays within the Notify app sandbox
