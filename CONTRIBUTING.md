# Contributing

## Prerequisites

- macOS 13 or later
- Xcode Command Line Tools
- Logi Options+ and Flow for physical handoff validation

## Workflow

1. Create a focused branch.
2. Make the smallest change that solves the issue.
3. Run `./scripts/check.sh`.
4. For Flow or overlay changes, complete the relevant steps in
   [VALIDATION.md](VALIDATION.md).
5. Open a pull request that explains the behavior change and its validation.

Do not commit `.build/`, `dist/`, diagnostic logs, mounted images, or local IDE
state.

## Code style

- Keep Flow-state transitions deterministic and testable outside AppKit.
- Keep overlay windows non-interactive so they cannot block recovery input.
- Treat display geometry as a combined desktop; local display seams are not Flow
  edges.
- Document the current behavior without migration history.

## Bug reports

Include:

- macOS and Logi Options+ versions
- Mouse model and connection type
- Display count and arrangement
- Selected trigger delay
- Relevant lines from `InputLinkTips.log`

Remove any information you do not want to publish before attaching logs.
