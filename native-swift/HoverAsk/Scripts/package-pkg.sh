#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
APP_DIR="$ROOT_DIR/outputs/HoverAsk.app"
PKG_ROOT="$ROOT_DIR/outputs/HoverAsk-pkg-root"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/native-swift/HoverAsk/Resources/Info.plist")"
IDENTIFIER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$ROOT_DIR/native-swift/HoverAsk/Resources/Info.plist")"
PKG_PATH="$ROOT_DIR/outputs/HoverAsk-v${VERSION}-macos.pkg"

if [ ! -d "$APP_DIR" ]; then
  "$ROOT_DIR/native-swift/HoverAsk/Scripts/build.sh"
fi

rm -rf "$PKG_ROOT" "$PKG_PATH"
mkdir -p "$PKG_ROOT/Applications"
ditto --noextattr --noqtn "$APP_DIR" "$PKG_ROOT/Applications/HoverAsk.app"
find "$PKG_ROOT" -name '._*' -type f -delete
xattr -cr "$PKG_ROOT" 2>/dev/null || true

COPYFILE_DISABLE=1 pkgbuild \
  --root "$PKG_ROOT" \
  --install-location "/" \
  --identifier "$IDENTIFIER" \
  --version "$VERSION" \
  "$PKG_PATH"

pkgutil --check-signature "$PKG_PATH" || true
PAYLOAD_LIST="$(pkgutil --payload-files "$PKG_PATH")"
grep -q '^\./Applications/HoverAsk.app/Contents/MacOS/HoverAsk$' <<<"$PAYLOAD_LIST"

rm -rf "$PKG_ROOT"

echo "$PKG_PATH"
