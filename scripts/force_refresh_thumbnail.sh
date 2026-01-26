#!/bin/bash
# Force refresh screensaver thumbnail by clearing all caches

set -e

echo "🔄 Force refresh van screensaver thumbnail..."

BUNDLE="$HOME/Library/Screen Savers/StorySellerSaver.saver"

if [ ! -d "$BUNDLE" ]; then
    echo "❌ Screensaver bundle niet gevonden: $BUNDLE"
    exit 1
fi

# 1. Update both Preview.png and thumbnail.tiff in bundle
if [ -f "StorySellerSaver/Preview.png" ]; then
    cp StorySellerSaver/Preview.png "$BUNDLE/Preview.png"
    cp StorySellerSaver/Preview.png "$BUNDLE/Contents/Resources/Preview.png"
    echo "✅ Preview.png bijgewerkt"
fi

if [ -f "StorySellerSaver/thumbnail.tiff" ]; then
    cp StorySellerSaver/thumbnail.tiff "$BUNDLE/Contents/Resources/thumbnail.tiff"
    echo "✅ thumbnail.tiff bijgewerkt"
fi

# 2. Clear all System Settings caches
echo "🗑️  Wissen van caches..."
rm -rf ~/Library/Caches/com.apple.preferencepanes.* 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.systempreferences.* 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.ScreenSaver.* 2>/dev/null || true
rm -rf ~/Library/Caches/System\ Settings.* 2>/dev/null || true

# 3. Clear QuickLook cache (thumbnails are often cached here)
qlmanage -r cache 2>/dev/null || true
echo "✅ QuickLook cache gewist"

# 4. Kill System Settings completely
echo "🛑 Sluiten van System Settings..."
killall -9 "System Settings" 2>/dev/null || true
killall -9 SystemPreferences 2>/dev/null || true
sleep 2

# 5. Touch bundle to force refresh
touch "$BUNDLE" 2>/dev/null || echo "⚠️  Kon bundle timestamp niet updaten (permissions)"

echo ""
echo "✅ Klaar! Volg deze stappen:"
echo "   1. Wacht 5 seconden"
echo "   2. Open System Settings → Screen Saver"
echo "   3. Als je de oude thumbnail nog ziet, scroll weg en terug"
echo "   4. Of herstart je Mac (extreme maar effectief)"
echo ""
echo "💡 Tip: De thumbnail wordt gecached door macOS. Soms helpt het om"
echo "   de screensaver te selecteren en dan weg te scrollen en terug te komen."
