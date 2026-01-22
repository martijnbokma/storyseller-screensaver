#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: preview_screensaver.sh [options] [/path/to/StorySellerSaver.saver]

Options:
  --debug         Use Debug build (default)
  --release       Use Release build
  --build         Run xcodebuild before installing
  --clean         Remove existing installed saver before copying
  --no-bump       Don't bump CFBundleVersion/ShortVersion (default: bump with timestamp)
  --no-restart    Don't restart ScreenSaverEngine
  -h, --help      Show this help
USAGE
}

CONFIG="Debug"
CLEAN=0
RESTART=1
DO_BUILD=0
BUMP_VERSION=1
SRC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) CONFIG="Debug"; shift ;;
    --release) CONFIG="Release"; shift ;;
    --build) DO_BUILD=1; shift ;;
    --clean) CLEAN=1; shift ;;
    --no-bump) BUMP_VERSION=0; shift ;;
    --no-restart) RESTART=0; shift ;;
    -h|--help) usage; exit 0 ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      SRC="$1"
      shift
      ;;
  esac
done

DEST_DIR="$HOME/Library/Screen Savers"
DEST="$DEST_DIR/StorySellerSaver.saver"

if [[ "$DO_BUILD" -eq 1 ]]; then
  /usr/bin/xcodebuild \
    -project "StorysellerScreensaver.xcodeproj" \
    -scheme "StorySellerSaver" \
    -configuration "$CONFIG" \
    -destination 'platform=macOS' \
    build 2>&1 | grep -v -E "(DVTErrorPresenter|CoreSimulator|iOSSimulator|SimServiceContext|DVTCoreSimulatorAdditionsErrorDomain|out-of-date|out of date|Recovery Suggestion.*CoreSimulator|Simulator device support disabled|^Code: [0-9]+$|^Recovery Suggestion:)" >/dev/null || true
fi

if [[ -z "$SRC" ]]; then
  DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
  PATTERN="*/Build/Products/$CONFIG/StorySellerSaver.saver"
  if [[ -d "$DERIVED" ]]; then
    SRC="$(/bin/ls -td "$DERIVED"/$PATTERN 2>/dev/null | /usr/bin/head -n 1 || true)"
  fi
fi

if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "Error: Could not find StorySellerSaver.saver (config: $CONFIG)." >&2
  echo "Pass an explicit path or build the target first." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
if [[ "$CLEAN" -eq 1 ]]; then
  rm -rf "$DEST"
fi
/usr/bin/ditto "$SRC" "$DEST"

if [[ "$BUMP_VERSION" -eq 1 ]]; then
  TS="$(date +%Y%m%d%H%M%S)"
  INFO_PLIST="$DEST/Contents/Info.plist"
  if [[ -f "$INFO_PLIST" ]]; then
    /usr/bin/plutil -replace CFBundleVersion -string "$TS" "$INFO_PLIST"
    /usr/bin/plutil -replace CFBundleShortVersionString -string "1.0.$TS" "$INFO_PLIST"
    echo "Bumped version to: 1.0.$TS (CFBundleVersion=$TS)"
  else
    echo "Warning: Info.plist not found at $INFO_PLIST; skipped version bump." >&2
  fi
fi

if [[ "$RESTART" -eq 1 ]]; then
  /usr/bin/pkill -x ScreenSaverEngine >/dev/null 2>&1 || true
  open /System/Library/CoreServices/ScreenSaverEngine.app
fi

echo "Installed: $DEST"
