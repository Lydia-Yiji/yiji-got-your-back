#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD_DIR="$ROOT/desktop/build"
DIST_DIR="$ROOT/dist"
APP_NAME="Yiji Focus Float.app"
APP_DIR="$DIST_DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BIN="$MACOS_DIR/YijiFocusFloat"
MODULE_CACHE="$BUILD_DIR/module-cache"

mkdir -p "$BUILD_DIR" "$DIST_DIR" "$MODULE_CACHE"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp -R "$ROOT/prototype" "$RESOURCES_DIR/prototype"
cp -R "$ROOT/prototype/motions/idle" "$RESOURCES_DIR/idle-frames"
cp -R "$ROOT/prototype/motions/running" "$RESOURCES_DIR/running-frames"
cp -R "$ROOT/prototype/motions/jumping" "$RESOURCES_DIR/jumping-frames"
cp -R "$ROOT/prototype/motions/waving" "$RESOURCES_DIR/waving-frames"

export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE"

xcrun clang \
  -arch arm64 \
  -arch x86_64 \
  -fmodules \
  -fobjc-arc \
  -framework Cocoa \
  -framework CoreGraphics \
  "$ROOT/desktop/YijiDesktopFloat.m" \
  -o "$BIN"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>Yiji Focus Float</string>
  <key>CFBundleExecutable</key>
  <string>YijiFocusFloat</string>
  <key>CFBundleIdentifier</key>
  <string>com.yiji.focusfloat</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Yiji Focus Float</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

chmod +x "$BIN"
echo "$APP_DIR"
