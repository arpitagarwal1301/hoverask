# Privacy

HoverAsk V1 is designed as a local personal prototype.

## What HoverAsk Does

- Records microphone audio only when listening is started.
- Converts speech to text through macOS Speech Recognition.
- Sends the final text prompt to the selected local CLI provider process.
- Stores settings locally.
- Stores local history only when history is enabled.

## What HoverAsk Does Not Do

- Does not capture screenshots.
- Does not read browser pages.
- Does not scrape websites.
- Does not collect API keys.
- Does not run a remote backend owned by this app.

## Local Storage

HoverAsk stores app data in the user's Application Support directory under `HoverAsk`.

Stored data can include:

- Provider and UI settings.
- Optional local prompt/answer history.
- Provider runtime working files created by the local CLI process.

## Provider Data

When a provider is used, the prompt is passed to the installed CLI:

- Codex through `codex exec`.
- Claude through `claude -p`.

Those tools may communicate with their own services according to the account, product, and provider terms configured on the user's machine.
