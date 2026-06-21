# HoverAsk Roadmap

## June 22, 2026: Providers, History, Voice, Support

This roadmap tracks the next polish pass after the native macOS V1/V1.1 work. The goal is to make Settings feel like a one-stop control center for account CLIs, local models, BYOK providers, voice tests, chat history, and support links without making legal or support items visually dominant.

### Chat, Shortcut, And Prompt

- Convert Chat History into full conversation-style saved entries: user questions on the right, HoverAsk answers on the left, full text visible, per-bubble copy buttons, provider/timestamp metadata, and Load more batches.
- Change the global shortcut behavior:
  - If the assistant is hidden, show the avatar and open/listen.
  - If the avatar is visible and chat is closed, open chat and listen.
  - If chat is open, close only the chat chip and leave the avatar visible.
  - If thinking or listening, stop the active operation when closing.
- Replace the provider prompt with concise conversational behavior: same language as the user, Hinglish when mixed, short spoken-friendly answers by default, no fake screen awareness, and expand only when asked.
- Include only the current chat session context in prompts, not saved history.

### Provider One-Stop Settings

- Rework Providers as a route builder with source buckets and a selected-route inspector.
- Buckets:
  - Account CLIs: Codex, Claude, Cursor, OpenCode, Antigravity.
  - Private Local: Apple Intelligence, Ollama, LM Studio.
  - BYOK Cloud: OpenAI, Anthropic, Gemini, OpenRouter, Groq.
- Default Auto route:
  `Codex -> Claude -> Cursor -> OpenCode -> Antigravity -> Apple Intelligence -> Ollama -> LM Studio -> OpenAI -> Anthropic -> Gemini -> OpenRouter -> Groq`.
- Add per-provider controls:
  - CLI: Test, Login, Re-login, Disconnect from HoverAsk.
  - Local: Fetch models, Test, Disable.
  - BYOK: Connect, Fetch models, Test, Delete key, Disconnect.
- Disconnect for CLIs/local providers excludes them from HoverAsk routing; it does not log out of external apps or stop local servers.
- Keep the AI Assistant provider picker synced with only ready/enabled providers.

### BYOK And Model Selection

- Support multiple connected BYOK providers at once.
- A BYOK provider is usable only when it has both a Keychain API key and a selected or manually entered model ID.
- Use a unified `ProviderModelChoice` model with provider, model ID, effort, and display title.
- Model dropdowns show model plus effort combinations where effort is supported.
- Keep manual model ID entry visible when fetching fails or a provider requires a model that is not returned by its API.

### Voice

- Add Test microphone and Test speech recognition buttons in Voice settings.
- Microphone test checks permission and input level without sending audio to providers.
- Speech recognition test records a short phrase, shows transcript, and does not save history.

### Legal And Support

- Keep Privacy and Terms as subtle links in About/bottom app areas, not inside Voice.
- Overview keeps one banner: `Privacy by design · No screenshots · Keys in Keychain · Local providers stay on this Mac`.
- Support flow: the user creates the Buy Me a Coffee page and provides the final public URL. HoverAsk wires it into `SupportConfig.supportURL`, the sidebar bottom card, menu bar, README, and release notes.

### Implementation Status

- Providers have the new source-bucket layout, readiness states, route inspector, model controls, BYOK key actions, and disconnect controls.
- Chat History has full conversation bubbles, per-bubble copy, export actions, clear, count/storage, and Load more.
- Voice has microphone and speech recognition tests that do not call providers or save history.
- Shortcut behavior closes the chat chip without hiding the avatar.
- The prompt now uses current-session context only and stays concise/spoken-friendly.
