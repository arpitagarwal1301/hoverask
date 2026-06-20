#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
APP_DIR="$ROOT_DIR/outputs/HoverAsk.app"
DMG_ROOT="$ROOT_DIR/outputs/HoverAsk-dmg"
DMG_PATH="$ROOT_DIR/outputs/HoverAsk-v1.0.0-macos.dmg"

if [ ! -d "$APP_DIR" ]; then
  "$ROOT_DIR/native-swift/HoverAsk/Scripts/build.sh"
fi

rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DMG_ROOT"

cp -R "$APP_DIR" "$DMG_ROOT/HoverAsk.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "HoverAsk" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

hdiutil verify "$DMG_PATH"
rm -rf "$DMG_ROOT"

echo "$DMG_PATH"
