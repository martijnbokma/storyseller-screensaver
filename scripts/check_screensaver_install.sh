#!/usr/bin/env bash
set -euo pipefail

NAME="StorySellerSaver"
USER_DIR="$HOME/Library/Screen Savers"
SYS_DIR="/Library/Screen Savers"

echo "Checking installs for: $NAME"

print_info() {
  local bundle="$1"
  if [[ -d "$bundle" ]]; then
    local info="$bundle/Contents/Info.plist"
    local id=""
    local version=""
    local name=""
    if [[ -f "$info" ]]; then
      id=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$info" 2>/dev/null || true)
      version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$info" 2>/dev/null || true)
      name=$(/usr/libexec/PlistBuddy -c 'Print CFBundleName' "$info" 2>/dev/null || true)
    fi
    local mtime
    mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$bundle" 2>/dev/null || true)
    echo "- Found: $bundle"
    echo "  CFBundleName: ${name:-<missing>}"
    echo "  CFBundleIdentifier: ${id:-<missing>}"
    echo "  CFBundleShortVersionString: ${version:-<missing>}"
    echo "  Modified: ${mtime:-<unknown>}"
  fi
}

print_info "$USER_DIR/$NAME.saver"
print_info "$SYS_DIR/$NAME.saver"

if [[ ! -d "$USER_DIR/$NAME.saver" && ! -d "$SYS_DIR/$NAME.saver" ]]; then
  echo "No installed saver bundles found in user/system locations."
fi

echo ""
echo "Latest DerivedData builds:"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
for config in Debug Release; do
  PATTERN="*/Build/Products/$config/$NAME.saver"
  LATEST="$(/bin/ls -td "$DERIVED"/$PATTERN 2>/dev/null | /usr/bin/head -n 1 || true)"
  if [[ -n "$LATEST" && -d "$LATEST" ]]; then
    echo "$config:"
    print_info "$LATEST"
  else
    echo "$config: none found."
  fi
done
