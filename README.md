# Logitech Flow Overlay for macOS

[简体中文](docs/README.zh-CN.md)

An unofficial macOS menu bar utility that makes Logitech Flow handoffs visible.
When the pointer leaves the current Mac through Flow, the app places a prominent
glass overlay on every connected display. The overlay disappears as soon as the
pointer returns, then a short location alert dims the desktop and reveals a
circular highlight that follows the pointer.

> This project is not affiliated with or endorsed by Logitech.

## Features

- Full-screen glass overlay on every connected display
- Active-device detection on the left, right, top, and bottom desktop edges
- Multi-display awareness: seams between local displays do not trigger a handoff
- Immediate recovery when Logitech pointer input returns
- Mouse Reconnect Location Alert with a pointer-following spotlight
- Configurable reconnect-alert switch, screen dimming, duration, radius,
  edge feathering, and spotlight color
- Independent dark-tint transparency, system-glass intensity, and message settings
- Native macOS full-screen glass effect without screen-recording permission
- Dismiss button on the overlay for false positives and manual previews
- Configurable handoff delay: 0.2, 0.4, or 0.8 seconds
- Resizable, vertically scrollable main window for shorter displays
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

When a real handoff returns, the app replaces the departure overlay with one
non-interactive dimming window per display. The display containing the pointer
gets a feathered circular cutout that follows pointer movement for the configured
duration. Manually dismissing the departure overlay does not trigger this alert.
Temporary Logi Options+ process-availability gaps do not dismiss a confirmed
departure: only positive local pointer evidence or an explicit user action ends
the away state.

This is a heuristic. Parking the pointer at an external display edge can
occasionally look like a Flow handoff; increase the delay from the menu if needed.

## Build and run

```bash
./scripts/build_app.sh
open "dist/Logitech Flow Overlay.app"
```

The app opens a status window and remains available from both the Dock and menu
bar. Use **Overlay Settings** in the main window to adjust the dark tint,
system-glass intensity, or handoff message independently. Dragging either
slider shows the real full-screen overlay behind the raised main window.
Settings persist between launches. Closing the window does not stop
active-device detection.

The glass control maps the system material's visibly effective 60%–100% mask
range onto the full 0%–100% slider with a calibrated nonlinear response.
The midpoint maps to about 92% of the system material, matching its perceptual
response instead of using an equal-ratio conversion. It doesn't alter the
separate dark tint and doesn't require screen-recording permission.
New installations default to 20% dark-tint transparency and 80% glass effect.
The full-screen prompt keeps its icon and message inside a centered rounded
card, with a separate circular icon-only **X** button directly below it.

**Mouse Reconnect Location Alert** is enabled by default. Its settings control
the opacity outside the spotlight, the alert duration, the spotlight radius,
and the width of the soft edge transition. Use **Preview Alert** to check the
current values without performing a Flow handoff. These settings persist
between launches. New installations use 50% screen dimming, a 2.0-second
duration, a 100-point radius, 4% edge feathering, and a translucent white
spotlight color. The system color picker lets you choose any color and opacity;
changes appear in the live spotlight preview. The color affects only the
spotlight area and doesn't require screen-recording permission.

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
