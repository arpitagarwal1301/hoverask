# Security

HoverAsk V1 is a local macOS prototype. It does not expose a network server and does not accept remote connections.

## Provider Execution

HoverAsk invokes local provider CLIs through `Process`:

- Codex: `codex exec`
- Claude: `claude -p`

No API keys are requested or stored by HoverAsk.

## Distribution Status

V1 builds are ad-hoc signed for local testing. They are not Developer ID signed
or notarized. Treat release artifacts as private evaluation builds.

## Permissions

HoverAsk may request:

- Microphone access for voice input.
- Speech Recognition access for speech-to-text.

V1 does not request screen recording permission.

## Reporting

Because this repository is private for V1, report security concerns directly to the repository owner.

Please include:

- macOS version.
- HoverAsk version.
- Provider selected.
- Steps to reproduce.
- Relevant local logs or terminal output, with secrets removed.
