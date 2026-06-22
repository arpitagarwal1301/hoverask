# HoverAsk v1.2.0

![HoverAsk preview](https://raw.githubusercontent.com/arpitagarwal1301/hoverask/main/docs/assets/hoverask-v1-final-preview.png)

HoverAsk v1.2.0 polishes the Providers experience: cleaner routing, better provider states, current model defaults, and a more usable settings surface for CLI, local, and BYOK sources.

HoverAsk remains local-first by default: no screenshots, optional local history, and BYOK API keys stored only in macOS Keychain.

## Install

### Homebrew (recommended)

```sh
brew tap arpitagarwal1301/tap
brew install --cask hoverask
```

Homebrew installs from the release `.pkg`, so there is no DMG quarantine cleanup. It may ask for your macOS password while installing.

### Installer (`.pkg`)

1. Download **`HoverAsk-v1.2.0-macos.pkg`** from this release.
2. Open it; if macOS calls it "unidentified," **right-click -> Open** or use System Settings -> Privacy & Security -> **Open Anyway** once.
3. Click through the installer. HoverAsk lands in Applications.

### Disk image (`.dmg`)

1. Download **`HoverAsk-v1.2.0-macos.dmg`** from this release.
2. Drag **HoverAsk** into Applications.
3. If macOS says HoverAsk is damaged or blocked, clear quarantine once:
   ```bash
   xattr -dr com.apple.quarantine /Applications/HoverAsk.app
   open /Applications/HoverAsk.app
   ```

## Highlights

- Added a clearer selected-route inspector for Auto fallback routing.
- Added draggable route chips, visible edit handles, and add/remove fallback controls.
- Simplified provider bucket toggles to `Show all` and `Show top`.
- Made provider overflow menus state-aware.
- Auto-cleared transient provider success/status messages while keeping real errors visible.
- Aligned Apple Intelligence with other Local provider rows.
- Reused one consistent `Privacy by design` banner on Overview and Providers.
- Refreshed built-in model defaults for OpenAI, Anthropic, Gemini, OpenRouter, Groq, Ollama, and LM Studio.
- Added a `.pkg` installer and Homebrew cask install path.

## Artifacts

- `HoverAsk-v1.2.0-macos.pkg`
  - SHA-256: `b7652d8b1599d7bff4e20026c1291c4676d554da83fba947d56c45cfdb178c41`
- `HoverAsk-v1.2.0-macos.dmg`
  - SHA-256: `8ff0f4b39708ff9506cbeb82099c063be2f2f11e62222160a7c50bd2fc3dbc5f`

## Requirements

- macOS 14 or newer on Apple Silicon.
- Microphone and Speech Recognition permissions for voice input.
- Optional logged-in CLI accounts, local model servers, or BYOK API keys depending on the provider route you use.

## Notes

HoverAsk is a local prototype. It is proprietary software and no open-source license is granted.

The app and installer are not Developer ID notarized yet. Homebrew and the `.pkg` are the smoothest install paths; the `.dmg` remains available for manual installation.
