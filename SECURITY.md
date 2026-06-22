# Security

HoverAsk is a local macOS prototype. It does not expose a network server and does not accept remote connections.

## Provider Execution

HoverAsk can route prompts through local command-line tools using `Process`:

- Codex: `codex exec`
- Claude: `claude -p`
- Cursor: `cursor-agent`
- OpenCode: `opencode`
- Antigravity: `agy`

These tools run with the user's local accounts and configurations. HoverAsk does not log users out of those tools or manage their external account state; disconnecting a provider only excludes it from HoverAsk routing.

## BYOK API Keys

HoverAsk supports bring-your-own-key providers: OpenAI, Anthropic, Gemini, OpenRouter, and Groq.

API keys are stored only in macOS Keychain:

- Keychain service: `app.hoverask.byok`
- Keychain account: the provider raw value, such as `openAI` or `anthropic`
- Accessibility: this-device-only Keychain storage after first unlock

Keys are not stored in `UserDefaults`, local history, logs, release artifacts, docs, or plain files. Delete a BYOK key from Settings -> Providers, or through macOS Keychain Access.

## Local Data

HoverAsk may store:

- Settings in `UserDefaults`.
- Optional chat history in Application Support under `HoverAsk`.
- Provider runtime files under `HoverAsk/assistant-runtime`.

Chat history can be disabled, cleared, or exported from Settings. Exports contain prompts, answers, provider labels, and timestamps; they do not include API keys.

## Permissions

HoverAsk may request:

- Microphone access for voice input.
- Speech Recognition access for speech-to-text.

HoverAsk does not request Screen Recording permission and does not capture screenshots or read other apps.

## Distribution Status

Current builds are ad-hoc signed or unsigned for local testing. They are not Developer ID signed or notarized. Release artifacts are distributed through GitHub Releases and the `arpitagarwal1301/homebrew-tap` Homebrew tap.

## Reporting

Because this repository is private/proprietary, report security concerns directly to the repository owner.

Please include:

- macOS version.
- HoverAsk version.
- Provider selected.
- Steps to reproduce.
- Relevant local logs or terminal output, with prompts, account data, and secrets removed.
