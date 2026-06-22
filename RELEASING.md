# Releasing HoverAsk

This checklist describes the current manual release flow for HoverAsk.

## Source Of Truth

- Version source: `native-swift/HoverAsk/Resources/Info.plist`
- Field: `CFBundleShortVersionString`
- Bundle ID: `com.arpitagarwal.hoverask`
- Homebrew tap: `arpitagarwal1301/homebrew-tap`
- Current release artifacts:
  - `outputs/HoverAsk-v<version>-macos.pkg`
  - `outputs/HoverAsk-v<version>-macos.dmg`

## 1. Prepare The Version

Manual:

1. Choose the next version, for example:
   ```bash
   export VERSION=1.2.1
   ```
2. Update the app version:
   ```bash
   /usr/libexec/PlistBuddy \
     -c "Set :CFBundleShortVersionString $VERSION" \
     native-swift/HoverAsk/Resources/Info.plist
   ```
3. Update public docs that mention the release:
   - `CHANGELOG.md`
   - `RELEASE_NOTES.md`
   - `README.md` artifact names if the visible version changes
4. Verify the source-of-truth version:
   ```bash
   /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' native-swift/HoverAsk/Resources/Info.plist
   ```

## 2. Build And Package

Automated by local scripts:

```bash
native-swift/HoverAsk/Scripts/build.sh
native-swift/HoverAsk/Scripts/package-pkg.sh
native-swift/HoverAsk/Scripts/package-dmg.sh
```

Expected outputs:

```bash
outputs/HoverAsk.app
outputs/HoverAsk-v${VERSION}-macos.pkg
outputs/HoverAsk-v${VERSION}-macos.dmg
```

Validate:

```bash
plutil -lint native-swift/HoverAsk/Resources/Info.plist
file outputs/HoverAsk.app/Contents/MacOS/HoverAsk
pkgutil --check-signature "outputs/HoverAsk-v${VERSION}-macos.pkg" || true
pkgutil --payload-files "outputs/HoverAsk-v${VERSION}-macos.pkg" | rg 'Applications/HoverAsk.app/Contents/MacOS/HoverAsk'
hdiutil verify "outputs/HoverAsk-v${VERSION}-macos.dmg"
shasum -a 256 "outputs/HoverAsk-v${VERSION}-macos.pkg" "outputs/HoverAsk-v${VERSION}-macos.dmg"
```

Manual smoke check:

```bash
open outputs/HoverAsk.app
```

Check the floating avatar, settings window, provider list, voice permission flow, and one safe provider test if credentials are available.

## 3. Commit And Tag

Manual:

```bash
git status --short
git add native-swift/HoverAsk/Resources/Info.plist README.md CHANGELOG.md RELEASE_NOTES.md
git commit -m "chore: release HoverAsk v${VERSION}"
git tag "v${VERSION}"
git push origin main
git push origin "v${VERSION}"
```

If additional source changes are part of the release, stage those explicitly. Do not stage `PROMOTION.md`.

## 4. Publish GitHub Release

Manual with GitHub CLI:

```bash
gh release create "v${VERSION}" \
  "outputs/HoverAsk-v${VERSION}-macos.pkg" \
  "outputs/HoverAsk-v${VERSION}-macos.dmg" \
  --repo arpitagarwal1301/hoverask \
  --title "HoverAsk v${VERSION}" \
  --notes-file RELEASE_NOTES.md
```

For an existing release:

```bash
gh release edit "v${VERSION}" \
  --repo arpitagarwal1301/hoverask \
  --notes-file RELEASE_NOTES.md
```

Verify:

```bash
gh release view "v${VERSION}" \
  --repo arpitagarwal1301/hoverask \
  --json url,assets
```

## 5. Update Homebrew

Manual in the separate tap repo:

```bash
cd /Users/arpit/Documents/Codex/2026-06-20/homebrew-tap
```

Update `Casks/hoverask.rb`:

- `version "$VERSION"`
- `sha256 "<pkg sha256>"`
- URL remains:
  `https://github.com/arpitagarwal1301/hoverask/releases/download/v#{version}/HoverAsk-v#{version}-macos.pkg`

Validate:

```bash
brew audit --cask arpitagarwal1301/tap/hoverask
brew fetch --force --cask arpitagarwal1301/tap/hoverask
brew info --cask arpitagarwal1301/tap/hoverask
```

Full install validation requires an admin password:

```bash
brew install --cask hoverask
brew uninstall --cask hoverask
```

Commit and push the tap:

```bash
git status --short
git add Casks/hoverask.rb README.md
git commit -m "Update HoverAsk cask to v${VERSION}"
git push origin master
```

## 6. Post-Release Checks

Manual:

- Confirm README install commands still match the released artifacts.
- Confirm `brew install --cask hoverask` resolves the new version.
- Confirm `.pkg` and `.dmg` SHA-256 values in `RELEASE_NOTES.md` match the uploaded files.
- Confirm `CHANGELOG.md` has the new release entry.
- Confirm `PROMOTION.md`, if present locally, is still ignored by Git.

## Future Release Improvements

Not automated yet:

- Developer ID signing.
- Notarization.
- Sparkle or another update framework.
- A CI job that builds packages and validates markdown links/version references.
- A docs sync guard that checks `Info.plist`, README, release notes, Homebrew cask version, and artifact names agree.
