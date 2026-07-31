# Logitech Flow Overlay for macOS

[简体中文](docs/README.zh-CN.md)

An unofficial macOS menu bar utility that makes Logitech Flow handoffs visible.
When the pointer leaves the current Mac through Flow, the app places a prominent
glass overlay on every connected display. The overlay disappears as soon as the
pointer returns.

> This project is not affiliated with or endorsed by Logitech.

## Features

- Full-screen glass overlay on every connected display
- Flow detection on the left, right, top, and bottom edges of the desktop
- Multi-display awareness: seams between local displays do not trigger a handoff
- Immediate recovery when Logitech pointer input returns
- Configurable handoff delay: 0.2, 0.4, or 0.8 seconds
- Main window with live status, preview, and diagnostics
- Dock and menu bar access
- Chinese UI when Chinese is the primary system language; English otherwise
- No network requests or analytics

## Requirements

- macOS 13 or later
- Logitech Options+ running with Flow configured
- A Logitech mouse supported by Flow
- Xcode Command Line Tools when building from source

The current DMG build is for Apple Silicon Macs. The Swift source has no
third-party dependencies.

## Download

Download the current Apple Silicon installer from
[GitHub Releases](https://github.com/leo4stone/logitech-flow-overlay-macos/releases/latest).

Open the DMG and drag **Logitech Flow Overlay** onto the **Applications**
shortcut. The app is ad-hoc signed and is not notarized. If macOS blocks the
first launch, open **System Settings → Privacy & Security** and choose
**Open Anyway**.

## How it works

Logitech Options+ does not expose a stable public Flow-state API. The app infers
a handoff when all of these conditions are true:

1. The Logi Options+ application or its background device manager is running.
2. The pointer moves outward into an external edge of the combined desktop.
3. Local pointer movement stops for the configured delay.

The app tracks every `NSScreen` separately and creates one non-interactive overlay
window per display. Moving between two displays attached to the same Mac is not
treated as a Flow handoff.

This is a heuristic. Parking the pointer at an external display edge can
occasionally look like a Flow handoff; increase the delay from the menu if needed.

## Build and run

```bash
./scripts/build_app.sh
open "dist/Logitech Flow Overlay.app"
```

The app opens a status window and remains available from both the Dock and menu
bar. Closing the window does not stop Flow monitoring.

## Build an unsigned DMG

```bash
./scripts/build_dmg.sh
```

The generated image is placed in `dist/`. Its Finder window contains the app,
an Applications shortcut, a drag direction, and the exact macOS security path
for opening the unnotarized build. Installation guidance is shown in Chinese
and English because a static Finder background cannot execute locale detection.

## Development

Run the automated checks:

```bash
./scripts/check.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution workflow and
[VALIDATION.md](VALIDATION.md) for the physical Flow and multi-display release
checklist.

### Project layout

```text
Sources/LogitechFlowOverlay/       App lifecycle, window, detector, HID, overlays
Tests/LogitechFlowOverlayTests/    Flow geometry and Options+ runtime tests
Resources/                         App metadata, icon, and DMG artwork
scripts/                           App, icon, DMG, and validation scripts
```

## Diagnostics and privacy

Use **Open Diagnostic Log** from the menu bar app to inspect Flow candidates,
handoffs, device state, and overlay windows. The log is written to the current
macOS temporary directory as `LogitechFlowOverlay.log`.

The app reads local screen geometry, pointer position, running-app state, and
Logitech HID metadata. It does not send or store data outside the Mac.

## License

No license is currently granted. All rights are reserved unless a license is
added by the repository owner.
