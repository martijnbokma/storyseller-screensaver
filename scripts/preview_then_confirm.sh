#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: preview_then_confirm.sh [options]

Options:
  --debug         Use Debug build (default)
  --release       Use Release build
  --no-build      Skip xcodebuild
  --no-clean      Don't remove existing install first
  -h, --help      Show this help
USAGE
}

CONFIG="Debug"
DO_BUILD=1
DO_CLEAN=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) CONFIG="Debug"; shift ;;
    --release) CONFIG="Release"; shift ;;
    --no-build) DO_BUILD=0; shift ;;
    --no-clean) DO_CLEAN=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

NAME="StorySellerSaver"
DEST_DIR="$HOME/Library/Screen Savers"
DEST="$DEST_DIR/$NAME.saver"
SYS_DEST="/Library/Screen Savers/$NAME.saver"

if [[ -x "scripts/check_screensaver_install.sh" ]]; then
  echo ""
  scripts/check_screensaver_install.sh
  echo ""
  read -r -p "Do you want to continue with build/install? [y/N] " PREVIEW_CONFIRM
  case "$PREVIEW_CONFIRM" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Cancelled."; exit 0 ;;
  esac
fi

if [[ "$DO_BUILD" -eq 1 ]]; then
  /usr/bin/xcodebuild \
    -project "StorysellerScreensaver.xcodeproj" \
    -scheme "$NAME" \
    -configuration "$CONFIG" \
    build >/dev/null
fi

DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
PATTERN="*/Build/Products/$CONFIG/$NAME.saver"
SRC="$(/bin/ls -td "$DERIVED"/$PATTERN 2>/dev/null | /usr/bin/head -n 1 || true)"
if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "Error: Could not find $NAME.saver (config: $CONFIG)." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
if [[ "$DO_CLEAN" -eq 1 ]]; then
  rm -rf "$DEST"
  if [[ -d "$SYS_DEST" ]]; then
    echo "Removing system install: $SYS_DEST (requires sudo)"
    /usr/bin/sudo rm -rf "$SYS_DEST"
  fi
fi
/usr/bin/ditto "$SRC" "$DEST"

read -r -p "Open preview now? [y/N] " OPEN_PREVIEW
case "$OPEN_PREVIEW" in
  [yY]|[yY][eE][sS])
    /usr/bin/pkill -x ScreenSaverEngine >/dev/null 2>&1 || true
    open /System/Library/CoreServices/ScreenSaverEngine.app
    echo ""
    echo "Preview running from: $DEST"
    ;;
  *)
    echo "Preview skipped."
    ;;
esac

read -r -p "Keep this build installed? [y/N] " REPLY
case "$REPLY" in
  [yY]|[yY][eE][sS])
    echo "Kept: $DEST"
    ;;
  *)
    /usr/bin/pkill -x ScreenSaverEngine >/dev/null 2>&1 || true
    rm -rf "$DEST"
    echo "Removed: $DEST"
    ;;
esac
