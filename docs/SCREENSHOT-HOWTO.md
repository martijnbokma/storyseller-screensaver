# Making Screenshots of StorySellerSaver

This guide explains how to capture authentic screenshots of your screensaver in action.

## Method 1: Using macOS Screen Capture

### Step 1: Start the Screensaver
```bash
# Build and preview
make preview
```

### Step 2: Capture Screenshot
1. **Wait for screensaver** to start (it will automatically launch)
2. **Press** `Command + Shift + 3` for full screen capture
3. **Or press** `Command + Shift + 4` then `Space` and click the screensaver window
4. **Find screenshot** in `~/Desktop/` (named `Screenshot YYYY-MM-DD at HH.MM.SS.png`)

### Step 3: Stop the Screensaver
- **Move mouse** or **press any key** to exit screensaver
- **Close** the screensaver preview window

## Method 2: Using Terminal Commands

### Automatic Capture (Advanced)
```bash
# Build screensaver
make build

# Install screensaver
make install

# Start screensaver manually
open /System/Library/CoreServices/ScreenSaverEngine.app

# Wait a few seconds, then capture
screencapture -x ~/Desktop/storyseller-screenshot.png
```

## Tips for Great Screenshots

### Timing
- **Wait for logo movement**: The "CREATIVE BUSINESS" logo moves every 5 minutes
- **Capture during transition**: Best shots show word transitions
- **Multiple angles**: Capture different logo positions

### Settings
- **Full screen**: Use full resolution for best quality
- **Dark environment**: Screenshots look better in dark mode
- **High contrast**: The screensaver works best in high contrast environments

### Post-Processing
- **Crop**: Remove macOS UI elements if needed
- **Resize**: Scale down for web use while maintaining quality
- **Format**: PNG for transparency, JPG for smaller file size

## Troubleshooting

### Screensaver Won't Start
```bash
# Check if screensaver is installed
ls ~/Library/Screen\ Savers/ | grep StorySellerSaver

# Reinstall if missing
make clean && make install
```

### Screenshot is Blank
- Make sure screensaver is actually running
- Wait a moment for animation to start
- Try capturing again

### Low Quality Screenshots
- Use Retina display for higher resolution
- Capture at native screen resolution
- Don't resize in Preview app (use proper image editor)

## Example Workflow

```bash
# 1. Build and install
make install

# 2. Start screensaver
open /System/Library/CoreServices/ScreenSaverEngine.app

# 3. Wait for interesting animation state
# 4. Capture screenshot
screencapture ~/Desktop/storyseller-beautiful.png

# 5. Exit screensaver (move mouse)
```

The screensaver features smooth 60fps animations, so timing your screenshot capture will give you the best results! 📸✨