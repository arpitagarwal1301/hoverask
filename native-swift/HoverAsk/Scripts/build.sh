#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
APP_DIR="$ROOT_DIR/outputs/HoverAsk.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SOURCES_DIR="$ROOT_DIR/native-swift/HoverAsk/Sources"
INFO_PLIST="$ROOT_DIR/native-swift/HoverAsk/Resources/Info.plist"
APP_RESOURCES_DIR="$ROOT_DIR/native-swift/HoverAsk/Resources/AppResources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$INFO_PLIST" "$CONTENTS_DIR/Info.plist"
if [ -d "$APP_RESOURCES_DIR" ]; then
  cp -R "$APP_RESOURCES_DIR"/. "$RESOURCES_DIR"/
fi

swiftc \
  -O \
  -parse-as-library \
  -framework AppKit \
  -framework SwiftUI \
  -framework Speech \
  -framework AVFoundation \
  -framework Carbon \
  "$SOURCES_DIR"/*.swift \
  -o "$MACOS_DIR/HoverAsk"

codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
