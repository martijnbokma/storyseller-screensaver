# StorySellerSaver (macOS)

This is a minimal, working macOS Screen Saver written in Swift using the ScreenSaver framework.
It builds a `.saver` bundle you can install locally.

## Open in Xcode
Open `StorysellerScreensaver.xcodeproj`.

## Build
Product -> Build (⌘B)

The built screensaver will be located in:
`~/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/StorySellerSaver.saver`

## Install
1. Double-click the built `StorySellerSaver.saver` to install (recommended: install for current user).
2. Open System Settings -> Screen Saver and select **StorySellerSaver**.

## If macOS says it can't be opened
If Gatekeeper/quarantine blocks it (common when downloaded from the internet), remove the quarantine attribute:

```bash
xattr -dr com.apple.quarantine "/path/to/StorySellerSaver.saver"
```

Then try installing again.
