# Installing StorySellerSaver

This guide will help you install and configure the StorySellerSaver screensaver on your macOS system.

## 📋 System Requirements

- **macOS 10.15** or later (Catalina, Big Sur, Monterey, Ventura, Sonoma, Sequoia)
- **Intel or Apple Silicon** Macs supported
- **No additional software** required - just macOS!

## 🚀 Quick Installation

### Method 1: Download Pre-built Screensaver (Recommended)

1. **Go to Releases**: Visit the [latest release page](../../releases/latest)

2. **Download**: Download `StorySellerSaver.saver.zip`

3. **Extract**: Unzip the downloaded file

4. **Install**: Double-click `StorySellerSaver.saver`

5. **Configure**:
   - Open `System Settings` (or `System Preferences` on older macOS)
   - Go to `Screen Saver`
   - Select `StorySellerSaver` from the list

### Method 2: Build from Source

If you want to build the latest development version:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/storyseller-screensaver.git
   cd storyseller-screensaver
   ```

2. **Install development tools** (optional, for best experience):
   ```bash
   ./scripts/setup-dev.sh
   ```

3. **Build and install**:
   ```bash
   make install
   ```

## ⚙️ Configuration

### Basic Setup

1. Open `System Settings` → `Screen Saver`
2. **Find StorySellerSaver** in the list - look for the thumbnail showing:
   - Dark background with white text "create the story"
   - Subtle "CREATIVE BUSINESS" logo in corner
   - Elegant typography and glow effects
3. Select `StorySellerSaver` from the list
4. Adjust the activation time if desired

### Screen Saver Options

Currently, StorySellerSaver runs with optimized default settings. Future versions may include customizable options.

## 🔧 Troubleshooting

### "Can't be opened because Apple cannot check it for malicious software"

**Solution**: Remove the quarantine attribute

```bash
# Replace with the actual path to your .saver file
xattr -dr com.apple.quarantine "/path/to/StorySellerSaver.saver"
```

Then try installing again.

### Screensaver doesn't appear in System Settings

**Possible causes and solutions**:

1. **Installation failed**: Try reinstalling
2. **Wrong location**: Ensure the `.saver` file is in `~/Library/Screen Savers/`
3. **Permissions**: Make sure you have write access to the Screen Savers folder

### Performance Issues

- **High CPU usage**: The screensaver is optimized for 60fps. If you experience issues, it might be due to very large displays
- **Accessibility**: The screensaver automatically reduces motion for users who prefer reduced motion

### Fonts Not Displaying Correctly

The screensaver uses custom fonts and falls back gracefully:
- **Primary**: Cera Pro (if available or bundled)
- **Fallback**: Poppins → Avenir Next → Helvetica Neue → System Font

If you notice font issues:
- Ensure Cera Pro is installed (or bundled with the screensaver)
- See [Font Bundling Guide](../docs/FONT_BUNDLING.md) for details on bundling fonts
- The screensaver will automatically use fallback fonts if Cera Pro is not available

## 🎨 What You'll See

### In System Settings
When you open `System Settings` → `Screen Saver`, you'll see a grid of small preview thumbnails. Look for StorySellerSaver by its distinctive design:

![StorySellerSaver Thumbnail](docs/thumbnail-200x200.png)

**What makes it unique:**
- Dark, professional appearance (unlike colorful default screensavers)
- Clean typography with "create the story" text
- Subtle "CREATIVE BUSINESS" branding
- Minimalist design perfect for creative environments

### When Active
Once selected and running, StorySellerSaver displays:

- **Word carousel**: Action words cycling with "the story"
- **Floating logo**: "CREATIVE BUSINESS" moving around the screen
- **Ambient effects**: Breathing glow and subtle animations
- **Responsive design**: Scales beautifully on any screen size

## 📞 Getting Help

- **Check existing issues**: [GitHub Issues](../../issues)
- **Create a new issue**: If you encounter problems not listed here
- **Include system info**: macOS version, Mac model, any error messages

## 🔄 Updating

To update to a newer version:

1. Download the new `.saver` file
2. Replace the old one in `~/Library/Screen Savers/`
3. Restart System Settings if needed

## 🛠️ Uninstalling

To remove StorySellerSaver:

1. Go to `~/Library/Screen Savers/`
2. Delete `StorySellerSaver.saver`
3. Remove it from System Settings

The screensaver will automatically switch to the default macOS screensaver.

---

**Enjoy your new screensaver!** 🎨✨