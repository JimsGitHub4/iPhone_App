# SafeCheck

An iOS "dead man's switch" app. If the owner does not check in within a preset
window, the app prompts **"Are you OK?"**, then escalates to notifying their
pre-selected emergency contacts so someone can perform a safety check.

**Status: in development.** It builds, but the core timing/escalation logic is
not yet implemented — see _Known gaps_ below.

## Requirements

- Xcode 15 or later
- iOS 15.2 deployment target (iPhone and iPad)
- Swift 5

## Build

1. Open `SafeCheck.xcodeproj` — this is the only project file. There was once a
   duplicate `SafeCheck_1.xcodeproj`; it was deleted because it referenced a
   source file that no longer existed.
2. Select the `SafeCheck` scheme and a simulator or device.
3. Build and run (`Cmd-R`).

Contacts access requires the `NSContactsUsageDescription` privacy string, which
is set via the `INFOPLIST_KEY_NSContactsUsageDescription` build setting. Without
it the app is terminated by iOS the moment it asks for contacts permission.

## Repository layout

| Path | Purpose |
|---|---|
| `SafeCheckApp.swift` | `@main` entry point |
| `ContentView.swift` | Setup flow, contact selection, the "Are you OK?" prompt, and the inactivity timer |
| `CheckInManager.swift` | Earlier timer implementation — **unused** |
| `ContactsView.swift` | Placeholder list with hardcoded names — **unused** |
| `EmergencySendView.swift` | Stub alert screen — **unused** |

The three files marked unused are leftovers from three competing approaches.
They are still members of the build target, so they compile but are never shown.
They should be deleted in Xcode (which updates the project file safely) once the
canonical architecture is settled.

## Known gaps

- **The inactivity timer only runs while the app is open and in the foreground.**
  iOS suspends backgrounded apps within seconds, so a multi-hour countdown
  cannot survive on-device. The reliable design requires a server-side deadline
  plus the app sending periodic check-ins.
- **Sending the alert is not implemented.** iOS forbids programmatic SMS;
  `MessageUI` requires the user to tap Send, which is useless when the user is
  unresponsive. Escalation must be sent server-side (planned: Twilio).
- **The torch flash is not implemented.**
- The countdown values are hardcoded for testing (2 and 4 minutes), not the
  intended 48 hours.
- No tests.

## Conventions

Small commits, one concern each, imperative subject line
(`Fix brace bug in ContentView setup flow`). Never commit build output,
`xcuserdata/`, or credential files — `.gitignore` covers these.
