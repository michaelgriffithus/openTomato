# OpenTomato Privacy Policy

Effective 2026-09-01. Applies to the OpenTomato app for iOS, Android, and macOS.

## Summary

OpenTomato has no account, no server of its own, no analytics, no advertising,
no tracking, and no purchases. Everything you enter stays on your device unless
you choose to connect Home Assistant or to use the optional assistant with your
own API key. We do not collect any data about you.

## Data stored on your device

Plants, varieties, journal entries, photos, tasks, sensor readings, and settings
are stored in the app's own storage on your device. They are included in your
normal device backup and are deleted when you delete the app. We have no access
to them.

## Home Assistant

If you connect a Home Assistant server, the app talks to it over the network you
configure using a long-lived access token you create in Home Assistant. The app
only reads sensor states and history; it never writes to Home Assistant and
never sends your Home Assistant data anywhere else. The token is stored in the
device keychain, not in the app database.

## The optional assistant

The assistant is off until you paste an API key from a provider you choose
(currently Anthropic or OpenAI). The key is stored in the device keychain and
requests go directly from your device to that provider, billed to your key.

Before the first message, the app shows exactly what it will send: a short system
prompt, a context block built from your plants, recent journal entries, and
recent readings, and your own messages. Photos are never sent. Home Assistant
URLs, tokens, and entity identifiers are never sent. What the provider does with
the text you send is governed by that provider's own privacy policy.

## Permissions

- Camera and photo library: only to attach photos to your journal.
- Local network: only to reach your Home Assistant server.

The app requests nothing else.

## No tracking

OpenTomato contains no analytics, no advertising identifiers, no crash reporting
service, and no third-party SDK that collects data. Its App Store privacy label
is "Data Not Collected".

## Children

OpenTomato is a general-audience gardening tool and is not directed at children.
It collects no personal information from anyone.

## Changes

If this policy changes, the new version is published at this address and the
change is noted in the project changelog.

## Contact

OpenTomato is open source. Questions and concerns go to the project's issue
tracker: https://github.com/michaelgriffithus/openTomato/issues
