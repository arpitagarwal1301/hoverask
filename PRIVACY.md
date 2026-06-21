# HoverAsk Privacy Policy

Last updated: June 21, 2026

HoverAsk is a local-first macOS assistant. It is designed to run on your Mac and to send a prompt only to the answer source you choose, such as a logged-in CLI provider, a local model server, or a bring-your-own-key API provider.

This document is not legal advice. Review it before using HoverAsk as a public or commercial product.

## What HoverAsk Collects

HoverAsk may process:

- Microphone audio while listening is active.
- Speech transcripts created from that audio.
- Text prompts you type or dictate.
- Provider answers returned to the app.
- Local settings, such as avatar style, provider choice, model choice, hotkey, voice settings, and history preference.
- Optional local chat history when history is enabled.

## What HoverAsk Does Not Do

HoverAsk does not:

- Capture screenshots.
- Scrape browser pages or websites.
- Read the contents of other apps.
- Run a HoverAsk-owned remote backend.
- Add analytics or tracking in the current release.
- Store API keys in UserDefaults, chat history, logs, or plain files.

## Microphone And Speech Recognition

HoverAsk uses the microphone only when you start listening. macOS may ask for microphone and speech recognition permissions.

Speech-to-text is handled through macOS speech recognition APIs. Depending on your macOS configuration and language settings, Apple may process speech recognition according to Apple's own terms and privacy practices.

## Provider Data

When you ask a question, HoverAsk sends the final text prompt to the selected provider route.

Supported provider types include:

- Account-backed CLIs such as Codex, Claude, Cursor, OpenCode, and Antigravity.
- Private local sources such as Apple Intelligence where available, Ollama, or LM Studio.
- BYOK cloud providers such as OpenAI, Anthropic, Gemini, OpenRouter, and Groq.

Those providers may process prompts and answers according to their own accounts, terms, billing, retention, and privacy policies. HoverAsk does not control third-party provider data handling.

## BYOK API Keys

BYOK means "bring your own key." If you connect an API key, HoverAsk stores it only in macOS Keychain using the service name:

`app.hoverask.byok`

Keys are used only to call the provider you configured. HoverAsk does not export keys, show saved key values, include keys in chat history, or copy keys into diagnostics.

You can delete a saved key from HoverAsk settings. You can also manage Keychain items through macOS Keychain Access.

## Local Storage

HoverAsk stores local app data in your macOS Application Support directory under `HoverAsk`.

Local data can include:

- App settings.
- Optional chat history.
- Runtime working files used by provider CLIs.

Chat history is local-only in this release. You can disable history, clear it, or export it as Markdown or JSON from HoverAsk settings.

## Data Sharing

HoverAsk shares prompt text and provider requests only with the answer source you choose. It does not sell personal data.

If you use a cloud provider, your request is sent to that provider. If you use a local provider, the request stays on your Mac or local server unless that local provider is configured otherwise.

## Your Controls

You can:

- Disable local chat history.
- Clear saved chat history.
- Export saved chat history.
- Delete BYOK keys from Keychain.
- Change providers and models.
- Quit HoverAsk at any time.

## Contact

No public support contact is configured yet. If HoverAsk is published commercially, add a real contact address here and in the app's legal settings.
