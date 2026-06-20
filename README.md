# HoverAsk

HoverAsk is a native macOS floating voice assistant that sits above other apps. Tap the glass orb or companion, speak in English or Hinglish, and HoverAsk sends the transcribed question to your logged-in Codex or Claude CLI account. The answer appears in a compact anchored bubble and can be spoken aloud.

This is a personal/local V1 prototype. It does not use API keys, does not capture screenshots, and does not scrape browser content.

## Features

- Native SwiftUI/AppKit macOS app with a floating always-on-top panel.
- Voice-first question flow using macOS Speech Recognition and microphone input.
- Spoken replies using the built-in macOS speech synthesizer.
- Provider choices: Auto, Codex, or Claude.
- Account-backed execution through local CLIs:
  - `codex exec`
  - `claude -p`
- Minimal avatars: Glass Orb, Glass Dog, and Glass Cat.
- Optional companion movement: stationary, roam, or chase cursor.
- Local settings and optional local history.

## Requirements

- macOS 14 or newer.
- Xcode Command Line Tools with `swiftc`.
- A logged-in Codex CLI account for Codex provider support.
- A logged-in Claude Code CLI account for Claude provider support.
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

## Provider Auth

HoverAsk does not ask for API keys. It shells out to locally installed CLIs that are already logged in.

For Codex, install and log in to the Codex CLI, then verify:

```bash
codex --version
```

For Claude, install and log in to Claude Code, then verify:

```bash
claude --version
```

You can choose `Auto`, `Codex`, or `Claude` from HoverAsk settings. `Auto` tries Codex first, then falls back to Claude.

## Usage

1. Open HoverAsk.
2. Tap the orb or companion.
3. Speak a question in English or Hinglish.
4. Watch the live transcript bubble.
5. HoverAsk sends the final transcript to the selected provider.
6. Read and optionally hear the answer.

The status menu includes show/hide, settings, and quit controls.

## Privacy

- No screenshots or screen content are captured in V1.
- No browser scraping is performed.
- No API keys are collected.
- Prompts are sent only to the selected local CLI provider process.
- Settings and optional history are stored locally under the user's Application Support directory.

See [PRIVACY.md](PRIVACY.md) for details.

## Release Status

V1 is prepared as a private GitHub release while branding, assets, and distribution decisions remain under review. No open-source license is granted at this stage.
