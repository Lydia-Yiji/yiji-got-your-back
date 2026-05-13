#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$("$ROOT/scripts/build-app.sh")"
BIN="$APP_DIR/Contents/MacOS/YijiFocusFloat"
exec "$BIN"
