import Foundation
import AppKit

/// Centralized configuration for the screensaver.
/// All constants and configuration values are defined here to provide a single source of truth.
struct ScreensaverConfiguration {

    // MARK: - Animation Configuration

    /// Target frame rate for smooth animation.
    static let targetFrameRate: Double = 60.0

    /// Maximum delta time to prevent large jumps after frame drops.
    static let maxDeltaTime: CGFloat = 0.05

    /// Seconds for the movement between words.
    static let secondsPerWord: CGFloat = 1.2

    /// Seconds each word stays centered before moving on.
    static let holdSecondsPerWord: CGFloat = 0.6

    // MARK: - Visual Configuration

    /// Maximum visibility distance for words as a multiplier of line height.
    /// Words beyond this distance are culled from rendering.
    static let wordVisibilityMultiplier: CGFloat = 2.8

    /// Edge fade inner boundary as a multiplier of line height.
    /// Words within this distance have full opacity.
    static let edgeFadeInnerMultiplier: CGFloat = 1.8

    /// Logo size scaling factor relative to minimum screen dimension.
    static let logoSizeScale: CGFloat = 0.025

    /// Logo vertical spacing below carousel as multiplier of line height.
    static let logoSpacingMultiplier: CGFloat = 1.5

    /// Horizontal gap between the left word and the centered "the story".
    static let wordGap: CGFloat = 16

    /// Vertical offset to move the carousel slightly higher.
    static let carouselVerticalOffset: CGFloat = -25.0

    // MARK: - Performance Configuration

    /// Cache cleanup interval in seconds.
    static let cacheCleanupInterval: Int = 60

    // MARK: - Content Configuration

    /// Action words displayed in the carousel.
    static let words: [String] = ["create", "develop", "produce", "manage", "sell"]

    /// Center text that remains fixed while words rotate.
    static let centerText: String = "the story"

    /// Logo text displayed below the carousel.
    static let logoText: String = "CREATIVE BUSINESS"

    // MARK: - Typography Configuration

    /// Minimum font size for base typography.
    static let minFontSize: CGFloat = 34

    /// Maximum font size for base typography.
    static let minFontSizeMax: CGFloat = 72

    /// Base font size scaling factor relative to screen dimension.
    static let baseFontSizeScale: CGFloat = 0.095

    /// Word font size relative to story font size.
    static let wordFontSizeRatio: CGFloat = 0.92

    /// Word boost (emphasis) factor relative to story size.
    static let wordBoostRatio: CGFloat = 0.18

    /// Minimum word boost in points.
    static let minWordBoost: CGFloat = 6

    /// Line height multiplier relative to story font size.
    static let lineHeightMultiplier: CGFloat = 1.16

    /// Minimum line height in points.
    static let minLineHeight: CGFloat = 52

    /// Minimum screen dimension for calculations.
    static let minScreenDimension: CGFloat = 100

    // MARK: - Visual Effects Configuration

    /// Story text alpha component.
    static let storyTextAlpha: CGFloat = 0.9

    /// Story text kerning.
    static let storyTextKern: CGFloat = -0.2

    /// Word text kerning.
    static let wordTextKern: CGFloat = -0.15

    /// Logo text alpha component.
    static let logoTextAlpha: CGFloat = 0.3

    /// Logo text kerning.
    static let logoTextKern: CGFloat = 1.2

    /// Minimum word alpha (for edge fade).
    static let minWordAlpha: CGFloat = 0.02

    /// Maximum word alpha (for center word).
    static let maxWordAlpha: CGFloat = 0.98

    /// Shadow blur radius multiplier.
    static let shadowBlurRadiusMultiplier: CGFloat = 16

    /// Shadow color alpha multiplier.
    static let shadowColorAlphaMultiplier: CGFloat = 0.65

    /// Glow alpha component.
    static let glowAlpha: CGFloat = 0.07

    /// Glow radius multiplier relative to screen size.
    static let glowRadiusMultiplier: CGFloat = 0.35

    /// Vignette alpha component.
    static let vignetteAlpha: CGFloat = 0.45

    // MARK: - Background Configuration

    /// Background top color base red component.
    static let bgTopRed: CGFloat = 0.05

    /// Background top color base green component.
    static let bgTopGreen: CGFloat = 0.06

    /// Background top color base blue component.
    static let bgTopBlue: CGFloat = 0.08

    /// Background bottom color base red component.
    static let bgBottomRed: CGFloat = 0.01

    /// Background bottom color base green component.
    static let bgBottomGreen: CGFloat = 0.02

    /// Background bottom color base blue component.
    static let bgBottomBlue: CGFloat = 0.03

    /// Background phase shift multiplier.
    static let bgPhaseMultiplier: CGFloat = 0.2

    /// Background top shift base.
    static let bgTopShiftBase: CGFloat = 0.02

    /// Background top shift amplitude.
    static let bgTopShiftAmplitude: CGFloat = 0.01

    /// Background bottom shift base.
    static let bgBottomShiftBase: CGFloat = 0.01

    /// Background bottom shift amplitude.
    static let bgBottomShiftAmplitude: CGFloat = 0.01

    /// Background bottom phase offset.
    static let bgBottomPhaseOffset: CGFloat = 0.9

    // MARK: - Layout Configuration

    /// Story vertical offset for baseline alignment.
    static let storyVerticalOffset: CGFloat = 8.0

    /// Font-based space width multiplier.
    static let fontBasedSpaceMultiplier: CGFloat = 1.3

    /// Fixed space width in points.
    static let fixedSpaceWidth: CGFloat = 25
}
