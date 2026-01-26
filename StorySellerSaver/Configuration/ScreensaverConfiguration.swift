import AppKit

/// Centralized configuration for the screensaver
struct ScreensaverConfiguration {
    // MARK: - Animation

    /// Target frame rate for smooth animation
    static let targetFrameRate: Double = 60.0

    /// Maximum delta time to prevent large jumps after frame drops
    static let maxDeltaTime: CGFloat = 0.05

    /// Seconds for the movement between words
    static let secondsPerWord: CGFloat = 1.2

    /// Seconds each word stays centered before moving on
    static let holdSecondsPerWord: CGFloat = 0.6

    // MARK: - Visual

    /// Maximum visibility distance for words as a multiplier of line height.
    /// Words beyond this distance are culled from rendering.
    static let wordVisibilityMultiplier: CGFloat = 2.8

    /// Edge fade inner boundary as a multiplier of line height.
    /// Words within this distance have full opacity.
    static let edgeFadeInnerMultiplier: CGFloat = 1.8

    /// Logo size scaling factor relative to minimum screen dimension
    static let logoSizeScale: CGFloat = 0.025

    /// Logo vertical spacing below carousel as multiplier of line height
    static let logoSpacingMultiplier: CGFloat = 1.5

    /// Horizontal gap between the left word and the centered "the story"
    static let wordGap: CGFloat = 16

    /// Vertical offset to move the carousel slightly higher
    static let carouselVerticalOffset: CGFloat = -25.0

    // MARK: - Performance

    /// Cache cleanup interval in seconds
    static let cacheCleanupInterval: Int = 60

    // MARK: - Content

    /// Words displayed in the carousel
    static let words: [String] = ["create", "develop", "produce", "manage", "sell"]

    /// Center text displayed next to the carousel
    static let centerText: String = "the story"

    /// Logo text displayed below the carousel
    static let logoText: String = "CREATIVE BUSINESS"
}
