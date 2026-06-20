# HoverAsk v1.1.0

![HoverAsk preview](https://raw.githubusercontent.com/arpitagarwal1301/hoverask/main/docs/assets/hoverask-v1-final-preview.png)

HoverAsk v1.1.0 expands the local account-backed provider layer and cleans up Settings so the app is easier to run with the CLI accounts users already have.

The app remains local-first: no API keys are collected, no screenshots are captured, and provider requests are routed through installed CLIs on the user's Mac.

## Download

- [Download the macOS DMG](https://github.com/arpitagarwal1301/hoverask/releases/download/v1.1.0/HoverAsk-v1.1.0-macos.dmg)

## Highlights

- Added CLI provider support for Cursor, OpenCode, and Antigravity alongside Codex and Claude.
- `Auto` now uses ready-provider health checks before falling back through local CLIs.
- Settings now has clearer `CLI providers` rows with status, info, and login actions.
- Settings readability is improved with a darker glass panel and stronger section surfaces.
- Local history now shows saved count plus storage size and supports incremental `Load more`.
- Google Gemini is moved out of CLI providers and reserved for the future BYOK path.
- BYOK remains roadmap-only in this build; no API keys are requested or stored.

## Build Artifact

- `HoverAsk-v1.1.0-macos.dmg`

## Requirements

- macOS 14 or newer.
- Xcode Command Line Tools.
- Logged-in Codex CLI and/or Claude Code CLI.
- Optional Cursor, OpenCode, or Antigravity CLI for additional provider routes.
- Microphone and Speech Recognition permissions.

## Notes

This release is a local prototype. HoverAsk is proprietary software and no open-source license is granted.

The app is ad-hoc signed for local testing, not Developer ID notarized yet. macOS may require right-clicking the app and choosing Open on first launch.
