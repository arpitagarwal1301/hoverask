# HoverAsk

<p align="center">
  <img src="docs/assets/hoverask-v1-final-preview.png" alt="HoverAsk preview showing a native macOS floating voice assistant with a refractive glass orb, companion avatars, and anchored answer bubble" width="100%">
</p>

HoverAsk is a native macOS floating voice assistant that sits above other apps. Tap the glass orb or companion, speak in English or Hinglish, and HoverAsk sends the transcribed question to your selected AI source. The answer appears in a compact anchored bubble and can be spoken aloud.

This is a personal/local prototype. It supports logged-in CLI providers, local model servers, and optional BYOK providers with keys stored in macOS Keychain. It does not capture screenshots and does not scrape browser content.

## Download

Download the latest macOS build from the GitHub release.

### Recommended: PKG Installer

- [HoverAsk-v1.2.0-macos.pkg](https://github.com/arpitagarwal1301/hoverask/releases/download/v1.2.0/HoverAsk-v1.2.0-macos.pkg)

Open the `.pkg`, follow the installer, then launch HoverAsk from Applications. This is the smoothest path for most users because there is no drag-and-drop step and no Terminal command for the installed app.

HoverAsk is ad-hoc signed for local testing, not Developer ID notarized yet. If macOS blocks the installer itself, right-click the `.pkg`, choose Open, then confirm.

### Alternative: DMG

- [HoverAsk-v1.2.0-macos.dmg](https://github.com/arpitagarwal1301/hoverask/releases/download/v1.2.0/HoverAsk-v1.2.0-macos.dmg)
- [HoverAsk v1.2.0 release page](https://github.com/arpitagarwal1301/hoverask/releases/tag/v1.2.0)

Open the DMG, drag `HoverAsk.app` into Applications, then launch it. If macOS blocks the app after copying, run:

```bash
xattr -dr com.apple.quarantine /Applications/HoverAsk.app
open /Applications/HoverAsk.app
```

## Features

- Native SwiftUI/AppKit macOS app with a floating always-on-top panel.
- Voice-first question flow using macOS Speech Recognition and microphone input.
- Spoken replies using the built-in macOS speech synthesizer.
- Provider choices: Auto, account-backed CLIs, private local providers, or BYOK cloud providers.
- Account-backed execution through local CLIs:
  - `codex exec`
  - `claude -p`
  - `cursor-agent`
  - `opencode`
  - `agy`
- Functional provider rows with install/info/login, Keychain connect/delete, model selection, and test actions.
- Polished provider routing with a selected-route inspector, draggable fallback order, and source add/remove controls.
- BYOK providers: OpenAI, Anthropic, Gemini, OpenRouter, and Groq with local Keychain storage.
- Current built-in model suggestions for OpenAI, Anthropic, Gemini, OpenRouter, Groq, Ollama, and LM Studio.
- Private local providers: Apple Intelligence availability, Ollama, and LM Studio detection/testing.
- Minimal avatars: Glass Orb, Glass Dog, and Glass Cat.
- Privacy-safe refractive glass orb with visible idle/listening rings.
- Optional companion movement: stationary, roam, or chase cursor.
- More readable glass settings, local history size, incremental history loading, and Markdown/JSON history export.
- Editable global wake hotkey.

## Requirements

- macOS 14 or newer.
- Xcode Command Line Tools with `swiftc`.
- A logged-in Codex CLI account for Codex provider support.
- A logged-in Claude Code CLI account for Claude provider support.
- Optional logged-in Cursor CLI account for Cursor provider support.
- Optional configured OpenCode CLI for OpenCode provider support.
- Optional Antigravity CLI for Antigravity provider support.
- Optional API keys for BYOK cloud providers. Keys are stored only in macOS Keychain.
- Optional Ollama or LM Studio local servers for private local model routes.
- Microphone and Speech Recognition permissions granted to HoverAsk on first launch.

## Build

```bash
native-swift/HoverAsk/Scripts/build.sh
```

The app is created at:

```bash
outputs/HoverAsk.app
```

Launch it with:

```bash
open outputs/HoverAsk.app
```

## Package Installers

After building the app, create the recommended PKG installer with:

```bash
native-swift/HoverAsk/Scripts/package-pkg.sh
```

The PKG is created at:

```bash
outputs/HoverAsk-v1.2.0-macos.pkg
```

Create the alternative DMG with:

```bash
native-swift/HoverAsk/Scripts/package-dmg.sh
```

The DMG is created at:

```bash
outputs/HoverAsk-v1.2.0-macos.dmg
```

## Provider Auth And Keys

HoverAsk can shell out to locally installed CLIs that are already logged in, or it can use BYOK cloud providers whose keys are stored only in macOS Keychain under `app.hoverask.byok`.

For Codex, install and log in to the Codex CLI, then verify:

```bash
codex --version
```

For Claude, install and log in to Claude Code, then verify:

```bash
claude --version
```

Optional providers:

```bash
cursor-agent --version
opencode --version
agy --version
```

Only ready providers appear in quick provider pickers. `Auto` tries ready providers in this order: account CLIs, private local providers, then BYOK cloud providers.

BYOK providers can be connected from Settings -> Providers:

- OpenAI
- Anthropic
- Gemini
- OpenRouter
- Groq

Private local providers can be tested from Settings -> Providers:

- Apple Intelligence, when supported by macOS and the build SDK
- Ollama at `localhost:11434`
- LM Studio at `localhost:1234`

## Usage

1. Open HoverAsk.
2. Tap the orb or companion.
3. Speak a question in English or Hinglish.
4. Watch the live transcript bubble.
5. HoverAsk sends the final transcript to the selected provider.
6. Read and optionally hear the answer.

The status menu includes show/hide, settings, and quit controls.

## Privacy

- No screenshots or screen content are captured.
- No browser scraping is performed.
- BYOK API keys are stored only in macOS Keychain.
- Prompts are sent only to the selected provider route.
- Settings and optional history are stored locally under the user's Application Support directory.
- Saved chat history can be exported as Markdown or JSON.

See [PRIVACY.md](PRIVACY.md) for details.
See [TERMS.md](TERMS.md) for prototype terms and limitations.

## Third-Party Notices

HoverAsk includes MIT-licensed Lockpaw visual assets for the Glass Dog and Glass Cat companions. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Release Status

The current release is published for evaluation while branding, assets, and distribution decisions remain under review. HoverAsk is proprietary software; see [LICENSE](LICENSE).

## GitHub Visuals

The repository preview artwork lives at [docs/assets/hoverask-v1-final-preview.png](docs/assets/hoverask-v1-final-preview.png). Use it for GitHub's Social preview image so the project is recognizable when shared.
