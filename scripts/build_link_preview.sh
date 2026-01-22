#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: build_link_preview.sh [options]

Options:
  --debug         Use Debug build (default)
  --release       Use Release build
  -h, --help      Show this help
USAGE
}

CONFIG="Debug"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) CONFIG="Debug"; shift ;;
    --release) CONFIG="Release"; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

NAME="StorySellerSaver"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
DEST_DIR="$HOME/Library/Screen Savers"
DEST="$DEST_DIR/$NAME.saver"

/usr/bin/xcodebuild \
  -project "StorysellerScreensaver.xcodeproj" \
  -scheme "$NAME" \
  -configuration "$CONFIG" \
  -destination 'platform=macOS' \
  build 2>&1 | grep -v -E "(DVTErrorPresenter|CoreSimulator|iOSSimulator|SimServiceContext|DVTCoreSimulatorAdditionsErrorDomain|out-of-date|out of date|Recovery Suggestion.*CoreSimulator|Simulator device support disabled|^Code: [0-9]+$|^Recovery Suggestion:)" || true

PATTERN="*/Build/Products/$CONFIG/$NAME.saver"
SRC="$(/bin/ls -td "$DERIVED"/$PATTERN 2>/dev/null | /usr/bin/head -n 1 || true)"
if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "Error: Could not find $NAME.saver (config: $CONFIG)." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
rm -rf "$DEST"
ln -s "$SRC" "$DEST"

killall ScreenSaverEngine legacyScreenSaver 2>/dev/null || true
open /System/Library/CoreServices/ScreenSaverEngine.app

echo "Linked: $DEST -> $SRC"
