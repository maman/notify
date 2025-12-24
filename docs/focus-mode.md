# Focus Mode Integration

> **Requires:** macOS 15.0 (Sequoia) or later

Notify integrates with macOS Focus modes, allowing you to control which notifications break through when you need to concentrate.

**Related:** [Siri & Shortcuts](siri-shortcuts.md) · [URL Scheme Reference](url-scheme.md) · [MDM Configuration](mdm-configuration.md)

## Overview

When you enable a Focus mode (Do Not Disturb, Work, Personal, Sleep, etc.), Notify can filter notifications based on:

- **Specific topics** — Only allow notifications from certain topics
- **Priority levels** — Only allow notifications above a certain priority threshold

This ensures you only see critical alerts during focused work while silencing routine notifications.

## Setting Up Focus Filters

### Step 1: Open Focus Settings

1. Open **System Settings**
2. Click **Focus** in the sidebar
3. Select the Focus mode you want to configure (e.g., "Do Not Disturb" or "Work")

### Step 2: Add Notify to Allowed Apps

1. Under "Allowed Notifications", click **Apps**
2. Click the **+** button
3. Search for and select **Notify**
4. Click **Add**

### Step 3: Configure the Filter

After adding Notify, you can customize its behavior:

1. Click on **Notify** in the allowed apps list
2. You'll see the Notify Focus Filter options:

#### Filter Options

| Option | Description |
|--------|-------------|
| **Allow All Topics** | When enabled, all topics can send notifications (filtered by priority) |
| **Allowed Topics** | When "Allow All Topics" is off, select specific topics that can notify you |
| **Minimum Priority** | Only notifications at or above this priority level will break through |

### Priority Levels

ntfy supports 5 priority levels. Set your minimum threshold based on what's important:

| Priority | Value | Description | Example Use |
|----------|-------|-------------|-------------|
| Minimum | 1 | Lowest priority | Background updates |
| Low | 2 | Low importance | Routine notifications |
| Normal | 3 | Default priority | Standard alerts |
| High | 4 | Important | Requires attention soon |
| Urgent | 5 | Critical | Immediate attention required |

**Example:** Setting minimum priority to "High" means only High (4) and Urgent (5) notifications will appear during Focus mode.

## Configuration Examples

### Work Focus: Only Critical Alerts

When working, only receive urgent production alerts:

1. Set **Allow All Topics** to **Off**
2. Select only your `production-alerts` topic
3. Set **Minimum Priority** to **Urgent**

### Personal Focus: Specific Topics

During personal time, only receive home-related notifications:

1. Set **Allow All Topics** to **Off**
2. Select `home-security` and `family-updates` topics
3. Set **Minimum Priority** to **Normal**

### Sleep Focus: Block Everything

During sleep, block all Notify notifications:

1. Don't add Notify to allowed apps, OR
2. Set **Allow All Topics** to **Off** and select no topics

### Do Not Disturb: High Priority Only

During general DND, only receive important alerts from any topic:

1. Set **Allow All Topics** to **On**
2. Set **Minimum Priority** to **High**

## Sending Priority Notifications

To ensure your notifications break through Focus mode, send them with the appropriate priority:

```bash
# High priority - breaks through when minimum is set to High
curl -H "Priority: high" -d "Deployment needs approval" ntfy.sh/deploys

# Urgent priority - always breaks through (unless blocked)
curl -H "Priority: urgent" -d "Production is down!" ntfy.sh/alerts

# Default (normal) priority - may be filtered
curl -d "Build completed" ntfy.sh/ci-updates
```

### Priority Headers

| Header Value | Priority Level |
|--------------|----------------|
| `min` or `1` | Minimum |
| `low` or `2` | Low |
| `default` or `3` | Normal |
| `high` or `4` | High |
| `urgent`, `max`, or `5` | Urgent |

## How It Works

When Focus mode is active, Notify evaluates each incoming notification:

1. **Topic Check** — Is this topic in the allowed list (or are all topics allowed)?
2. **Priority Check** — Is the message priority >= minimum threshold?
3. **Delivery Decision** — If both checks pass, the notification is delivered; otherwise, it's silenced

Silenced notifications are still received and stored in Notify — they just don't trigger a visible notification or sound.

## Focus Across Devices

Focus settings sync across your Apple devices via iCloud. However, Notify's Focus Filter configuration is specific to each Mac where Notify is installed.

If you use multiple Macs:
- Configure Notify's Focus Filter on each Mac
- The Focus mode state (enabled/disabled) syncs automatically

## Troubleshooting

### Notifications Not Breaking Through

1. **Verify Focus Filter is configured** — Check System Settings → Focus → [Your Focus] → Apps → Notify
2. **Check the priority** — Ensure your notification priority meets the minimum threshold
3. **Verify topic is allowed** — If filtering by topic, confirm the topic is in the allowed list
4. **Test with urgent priority** — Send a test with `Priority: urgent` to verify the setup

### All Notifications Coming Through

1. **Check minimum priority** — If set to "Minimum", all notifications pass through
2. **Check "Allow All Topics"** — If enabled, topic filtering is bypassed
3. **Verify Focus is active** — Check the Control Center to confirm Focus is on

### Focus Filter Not Appearing

1. **Restart Notify** — Quit and reopen the app
2. **Check macOS version** — Focus Filters require macOS 15.0 or later
3. **Remove and re-add** — Remove Notify from allowed apps and add it again

## Automation Tips

Focus Filters are configured per Focus mode in System Settings. To change filter behavior based on context:

1. **Create multiple Focus modes** — Set up different Focus modes for different contexts (e.g., "Deep Work", "Meetings", "On-Call")
2. **Configure each differently** — Each Focus mode can have its own Notify filter settings
3. **Use Focus Schedules** — In System Settings → Focus, set up automatic schedules for when each Focus mode activates
4. **Use Focus Automations** — In Shortcuts, use "Set Focus" actions to switch between Focus modes based on time, location, or app usage

## Best Practices

1. **Use priority consistently** — Establish team conventions for when to use each priority level
2. **Don't over-filter** — Start with broader filters and narrow as needed
3. **Test your setup** — Send test notifications at each priority level to verify behavior
4. **Document your topics** — Know which topics are for critical vs. routine notifications
5. **Use Urgent sparingly** — Reserve Urgent priority for true emergencies to maintain its effectiveness
