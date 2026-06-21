# HoverAsk v1.1.0

![HoverAsk preview](https://raw.githubusercontent.com/arpitagarwal1301/hoverask/main/docs/assets/hoverask-v1-final-preview.png)

HoverAsk v1.1.0 expands the provider layer and cleans up Settings so the app is easier to run with CLI accounts, private local models, or BYOK cloud providers.

The app remains local-first by default: no screenshots are captured, local history is optional, and BYOK API keys are stored only in macOS Keychain.

## Download

- [Download the macOS DMG](https://github.com/arpitagarwal1301/hoverask/releases/download/v1.1.0/HoverAsk-v1.1.0-macos.dmg)

## Highlights

- Added CLI provider support for Cursor, OpenCode, and Antigravity alongside Codex and Claude.
- Added BYOK providers for OpenAI, Anthropic, Gemini, OpenRouter, and Groq with Keychain storage.
- Added private local provider detection/testing for Apple Intelligence, Ollama, and LM Studio.
- `Auto` now falls back through account CLIs, private local providers, then BYOK cloud providers.
- Providers now include model selection, effort controls where supported, and per-provider test actions.
- Settings has clearer sections: AI Assistant, Voice, Avatar, Providers, Chat History, and Advanced.
- Chat History now supports Markdown and JSON export.
- Advanced now focuses on editable wake hotkey and reset settings.
- Privacy and Terms docs are linked from the app and repository.

## Build Artifact

- `HoverAsk-v1.1.0-macos.dmg`

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

The app is ad-hoc signed for local testing, not Developer ID notarized yet. macOS may require right-clicking the app and choosing Open on first launch.
