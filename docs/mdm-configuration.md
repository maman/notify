# MDM Configuration Guide

> **Requires:** macOS 15.0 (Sequoia) or later

This guide explains how to deploy and configure Notify using Mobile Device Management (MDM) for enterprise environments.

**Related:** [Siri & Shortcuts](siri-shortcuts.md) · [Focus Mode Integration](focus-mode.md) · [URL Scheme Reference](url-scheme.md)

## Overview

Notify supports Apple's Managed App Configuration, allowing IT administrators to:

- Pre-configure ntfy server URLs and topics for users
- Enforce launch at login settings
- Deploy organization-wide notification topics that users cannot delete

## Configuration Schema

Notify reads managed configuration from the standard `com.apple.configuration.managed` UserDefaults key. The configuration is a dictionary with the following structure:

### Configuration Keys

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `topics` | Array | No | List of pre-configured topics |
| `launchAtLogin` | Boolean | No | Force enable/disable launch at login |

### Topic Configuration

Each topic in the `topics` array supports the following properties:

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `name` | String | Yes | The topic name to subscribe to |
| `serverURL` | String | No | Custom ntfy server URL (defaults to `https://ntfy.sh`) |
| `username` | String | No | Username for authenticated topics |

> **Note:** Passwords cannot be pre-configured via MDM for security reasons. Users must enter passwords manually for authenticated topics.

## Example Configuration

### Basic Configuration (Jamf Pro)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>launchAtLogin</key>
    <true/>
    <key>topics</key>
    <array>
        <dict>
            <key>name</key>
            <string>company-alerts</string>
            <key>serverURL</key>
            <string>https://ntfy.company.com</string>
        </dict>
        <dict>
            <key>name</key>
            <string>it-notifications</string>
            <key>serverURL</key>
            <string>https://ntfy.company.com</string>
            <key>username</key>
            <string>employee</string>
        </dict>
    </array>
</dict>
</plist>
```

### JSON Configuration (Kandji, Mosyle, etc.)

```json
{
  "launchAtLogin": true,
  "topics": [
    {
      "name": "company-alerts",
      "serverURL": "https://ntfy.company.com"
    },
    {
      "name": "it-notifications",
      "serverURL": "https://ntfy.company.com",
      "username": "employee"
    }
  ]
}
```

## MDM Platform Setup

### Jamf Pro

1. Navigate to **Computers** → **Configuration Profiles**
2. Create a new profile
3. Add an **Application & Custom Settings** payload
4. Select **External Applications** → **Add**
5. Set **Source** to "Custom Schema"
6. Enter bundle identifier: `me.mahardi.ntfy`
7. Paste the configuration plist

### Kandji

1. Navigate to **Library** → **Custom Apps**
2. Create a new custom app profile
3. Under **Managed Preferences**, add a new domain: `me.mahardi.ntfy`
4. Paste the JSON configuration

### Microsoft Intune

1. Navigate to **Devices** → **Configuration profiles**
2. Create a new profile for macOS
3. Select **Templates** → **Preference file**
4. Enter bundle identifier: `me.mahardi.ntfy`
5. Upload the configuration plist

### Mosyle

1. Navigate to **Management** → **Profiles**
2. Create a new macOS profile
3. Add **Custom Settings** → **Preference Domain**
4. Enter domain: `me.mahardi.ntfy`
5. Enter the configuration

## User Experience

### Managed Topics

Topics configured via MDM appear in the app with a lock icon, indicating they are managed by the organization. Users cannot:

- Delete managed topics
- Modify the server URL of managed topics
- Change the topic name

Users can still:

- View messages from managed topics
- Mark messages as read
- Add their own personal topics alongside managed ones

### Managed Settings

When `launchAtLogin` is set via MDM:

- The setting appears locked in the app preferences
- Users cannot toggle the setting
- A tooltip explains the setting is managed by their organization

## Troubleshooting

### Configuration Not Applied

1. Verify the profile is deployed to the device in your MDM console
2. Check the profile is installed: `profiles list` in Terminal
3. Verify the configuration:
   ```bash
   defaults read me.mahardi.ntfy
   ```

### Topics Not Appearing

1. Restart Notify after deploying the profile
2. Ensure the `name` key is present in each topic configuration
3. Check Console.app for any configuration parsing errors

### Authentication Issues

If a topic requires authentication:

1. The username can be pre-configured via MDM
2. Users must enter the password manually on first connection
3. Passwords are stored securely in the user's Keychain

## Security Considerations

- **Passwords are never pre-configured** — For security, passwords must be entered by users
- **Configuration is read-only** — Users cannot modify MDM-configured settings
- **Keychain isolation** — Each user's credentials are stored in their personal Keychain
- **No data exfiltration** — Notify does not send any data back to MDM servers

## Best Practices

1. **Use your own ntfy server** — For enterprise deployments, self-host ntfy for security and reliability
2. **Use authentication** — Protect topics with username/password authentication
3. **Test configurations** — Deploy to a test group before organization-wide rollout
4. **Document topics** — Maintain documentation of what each managed topic is used for
5. **Consider user topics** — Allow users to add personal topics for individual needs

## Support

For issues with MDM configuration:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review your MDM platform's documentation for app configuration
3. [Open an issue](https://github.com/maman/notify/issues) with your configuration (redact sensitive URLs)
