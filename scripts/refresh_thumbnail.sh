#!/bin/bash
# Refresh screensaver thumbnail cache

echo "🔄 Thumbnail cache verversen..."

# Update bundle timestamp
if [ -d ~/Library/Screen\ Savers/StorySellerSaver.saver ]; then
    touch ~/Library/Screen\ Savers/StorySellerSaver.saver
    touch ~/Library/Screen\ Savers/StorySellerSaver.saver/Preview.png
    echo "✅ Bundle timestamp bijgewerkt"
fi

# Clear System Settings cache
rm -rf ~/Library/Caches/com.apple.preferencepanes.* 2>/dev/null
rm -rf ~/Library/Caches/com.apple.systempreferences.* 2>/dev/null
echo "✅ System Settings cache gewist"

# Kill System Settings if running
killall System\ Settings 2>/dev/null
killall SystemPreferences 2>/dev/null

echo ""
echo "✅ Klaar! Open nu System Settings → Screen Saver om de nieuwe thumbnail te zien."
echo "   Als je de oude thumbnail nog ziet, wacht even of herstart System Settings."
