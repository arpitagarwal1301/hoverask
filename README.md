# HoverAsk

<p align="center">
  <img src="docs/assets/hoverask-v1-final-preview.png" alt="HoverAsk preview showing a native macOS floating voice assistant with a refractive glass orb, companion avatars, and anchored answer bubble" width="100%">
</p>

**HoverAsk** is a native macOS floating voice assistant that sits above your apps. Tap the glass orb or companion, speak in English or Hinglish, and get a text plus spoken answer from your chosen AI route.

It supports logged-in CLI accounts, private local model servers, and optional BYOK providers with keys stored in macOS Keychain. No screenshots, no browser scraping, no screen capture.

## Features

- Floating macOS assistant with glass orb, dog, and cat avatars.
- Voice-first flow with live transcript, typed fallback, and spoken replies.
- Account CLI providers: Codex, Claude, Cursor, OpenCode, and Antigravity.
- Private local providers: Apple Intelligence availability, Ollama, and LM Studio.
- BYOK cloud providers: OpenAI, Anthropic, Gemini, OpenRouter, and Groq.
- Provider routing with draggable fallback order and per-provider tests.
- Local chat history with Markdown/JSON export.
- Editable global wake shortcut.

> HoverAsk is not notarized by Apple yet. **Homebrew is the cleanest install** because it uses the release `.pkg` and avoids the DMG quarantine cleanup. Direct downloads work too, with one small one-time step if macOS blocks them.

### Homebrew (recommended)

```sh
brew tap arpitagarwal1301/tap
brew install --cask hoverask
```

Homebrew may ask for your macOS password while installing the package.

### Installer (`.pkg`)

1. Download **`HoverAsk-v1.2.0-macos.pkg`** from the [latest release](https://github.com/arpitagarwal1301/hoverask/releases/latest).
2. Open it; if macOS calls it "unidentified," **right-click -> Open** or use System Settings -> Privacy & Security -> **Open Anyway** once.
3. Click through the installer. HoverAsk lands in Applications.

### Disk image (`.dmg`)

1. Download **`HoverAsk-v1.2.0-macos.dmg`** from the [latest release](https://github.com/arpitagarwal1301/hoverask/releases/latest).
2. Drag **HoverAsk** into Applications.
3. If macOS says HoverAsk is damaged or blocked, clear quarantine once:
   ```bash
   xattr -dr com.apple.quarantine /Applications/HoverAsk.app
   open /Applications/HoverAsk.app
   ```

> Requires **macOS 14+** on Apple Silicon. HoverAsk asks only for Microphone and Speech Recognition permissions.

## Usage

1. Launch HoverAsk.
2. Tap the orb or companion, or press the global shortcut.
3. Speak or type a question.
4. HoverAsk routes it to the selected provider and shows the answer in the anchored chat chip.

Configure providers, voice, avatar, history, and BYOK keys from Settings.

## Provider Setup

Use any provider route you already have access to:

- CLI accounts: install and log in to `codex`, `claude`, `cursor-agent`, `opencode`, or `agy`.
- BYOK: connect OpenAI, Anthropic, Gemini, OpenRouter, or Groq from Settings -> Providers. Keys stay in macOS Keychain.
- Local: run Ollama at `localhost:11434` or LM Studio at `localhost:1234`.

Only ready providers appear in quick pickers. `Auto` tries ready CLI providers first, then private local providers, then BYOK cloud providers.

## Permissions

On first use, macOS may ask for:

- **Microphone** for voice input.
- **Speech Recognition** for converting speech to text.

HoverAsk does not request Screen Recording permission because it does not capture your screen.

## Build From Source

Requires Xcode Command Line Tools.

```bash
native-swift/HoverAsk/Scripts/build.sh
open outputs/HoverAsk.app
```

Release packaging scripts:

```bash
native-swift/HoverAsk/Scripts/package-pkg.sh
native-swift/HoverAsk/Scripts/package-dmg.sh
```

## More

- [Privacy](PRIVACY.md) · [Terms](TERMS.md)
- [Release notes](RELEASE_NOTES.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- Current release artifacts: `HoverAsk-v1.2.0-macos.pkg` and `HoverAsk-v1.2.0-macos.dmg`

HoverAsk is proprietary software; see [LICENSE](LICENSE).
