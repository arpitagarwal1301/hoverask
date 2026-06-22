# HoverAsk v1.2.0

![HoverAsk preview](https://raw.githubusercontent.com/arpitagarwal1301/hoverask/main/docs/assets/hoverask-v1-final-preview.png)

HoverAsk v1.2.0 focuses on the Providers experience: clearer routing, cleaner provider states, current model defaults, and a more polished settings surface for CLI, local, and BYOK sources.

The app remains local-first by default: no screenshots are captured, local history is optional, and BYOK API keys are stored only in macOS Keychain.

## Download

- Recommended: [Download the macOS PKG installer](https://github.com/arpitagarwal1301/hoverask/releases/download/v1.2.0/HoverAsk-v1.2.0-macos.pkg)
- Alternative: [Download the macOS DMG](https://github.com/arpitagarwal1301/hoverask/releases/download/v1.2.0/HoverAsk-v1.2.0-macos.dmg)

Use the `.pkg` first. If macOS blocks the unsigned installer, right-click the `.pkg`, choose Open, then approve it from System Settings -> Privacy & Security if needed.

Use the `.dmg` only for the manual drag-to-Applications flow. If macOS blocks the DMG-installed app, run:

```bash
xattr -dr com.apple.quarantine /Applications/HoverAsk.app
open /Applications/HoverAsk.app
```

## Highlights

- Added a clearer selected-route inspector for Auto fallback routing.
- Added draggable route chips, visible edit handles, and add/remove fallback controls.
- Simplified provider bucket toggles to `Show all` and `Show top`.
- Made provider overflow menus state-aware so unavailable providers avoid irrelevant disconnect actions.
- Changed provider success/status messages to auto-clear while keeping real errors visible.
- Aligned Apple Intelligence with other Local provider rows.
- Reused one consistent `Privacy by design` banner on Overview and Providers.
- Refreshed built-in model defaults and fallback suggestions for OpenAI, Anthropic, Gemini, OpenRouter, Groq, Ollama, and LM Studio.
- Added a PKG installer as the recommended no-Terminal installation path.

## Build Artifact

- `HoverAsk-v1.2.0-macos.pkg`
- `HoverAsk-v1.2.0-macos.dmg`

## Requirements

- macOS 14 or newer.
- Xcode Command Line Tools.
- Logged-in Codex CLI and/or Claude Code CLI.
- Optional Cursor, OpenCode, or Antigravity CLI for additional provider routes.
- Optional API keys for BYOK routes, stored in macOS Keychain.
- Optional Ollama or LM Studio local servers.
- Microphone and Speech Recognition permissions.

## Notes

This release is a local prototype. HoverAsk is proprietary software and no open-source license is granted.

The app and installer are ad-hoc signed/unsigned for local testing, not Developer ID notarized yet. The `.pkg` is the recommended install path; the `.dmg` remains available as an alternative with the quarantine cleanup step above.
