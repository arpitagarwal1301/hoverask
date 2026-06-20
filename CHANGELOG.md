# Changelog

## v1.1.0 - 2026-06-21

- Added account-backed CLI provider support for Cursor, OpenCode, and Antigravity alongside Codex and Claude.
- Updated Auto provider fallback to skip unavailable providers when health checks can identify ready CLIs.
- Reworked Settings provider status into a clearer `CLI providers` section with install/info/login affordances.
- Improved Settings readability with a darker glass panel and stronger group surfaces.
- Added local history storage size display and incremental `Load more` browsing.
- Moved Google Gemini out of CLI providers and into the future BYOK implementation path.
- Updated release docs and DMG packaging for the v1.1.0 build.

## v1.0.0 - 2026-06-20

- Prepared the native macOS app for release as HoverAsk.
- Renamed native bundle metadata, app output, menu labels, and app support paths.
- Replaced third-party-named mascot resources with clean-room Glass Orb, Glass Dog, and Glass Cat assets.
- Added transparent PNG animation frame sets for dog/cat states.
- Finalized the dog-glass orb with privacy-safe refraction and prominent idle/listening rings.
- Added GitHub-ready README, architecture, privacy, security, and release notes.
- Added a proprietary all-rights-reserved license posture for the private V1 release.
- Added a DMG packager for direct macOS installation.
- Kept the V1 repository focused on the native Swift app.
