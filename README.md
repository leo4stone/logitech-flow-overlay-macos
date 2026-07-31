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
- Menu bar preview and diagnostics
- No network requests or analytics

## Requirements

- macOS 13 or later
- Logitech Options+ running with Flow configured
- A Logitech mouse supported by Flow
- Xcode Command Line Tools when building from source

The current DMG build is for Apple Silicon Macs. The Swift source has no
third-party dependencies.

## How it works

Logitech Options+ does not expose a stable public Flow-state API. The app infers
a handoff when all of these conditions are true:

1. Logitech Options+ is running.
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
open dist/InputLinkTips.app
```

The app runs only in the menu bar and does not appear in the Dock.

## Build an unsigned DMG

```bash
./scripts/build_dmg.sh
```

The generated image is placed in `dist/`. It contains the app, an Applications
shortcut, and Chinese installation instructions.

The app is ad-hoc signed and is not notarized. After downloading it, first launch
it by Control-clicking the app and choosing **Open**. macOS may instead offer an
**Open Anyway** button in **System Settings → Privacy & Security**.

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
Sources/InputLinkTips/       App lifecycle, Flow detector, HID monitor, overlays
Tests/InputLinkTipsTests/    Flow edge and multi-display geometry tests
Resources/                   App metadata and DMG installation instructions
scripts/                     App, DMG, and validation scripts
```

## Diagnostics and privacy

Use **Open Diagnostic Log** from the menu bar app to inspect Flow candidates,
handoffs, device state, and overlay windows. The log is written to the current
macOS temporary directory as `InputLinkTips.log`.

The app reads local screen geometry, pointer position, running-app state, and
Logitech HID metadata. It does not send or store data outside the Mac.

## License

No license is currently granted. All rights are reserved unless a license is
added by the repository owner.
