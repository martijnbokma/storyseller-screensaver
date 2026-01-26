import Foundation
import AppKit

/// Handles all drawing operations for the screensaver.
final class ScreensaverRenderer {
    // MARK: - Properties

    /// Style manager for attributes.
    private let styleManager: StyleManager

    /// Font provider function.
    private let fontProvider: (CGFloat, NSFont.Weight) -> NSFont

    // MARK: - Initialization

    /// Initialize the renderer.
    /// - Parameters:
    ///   - styleManager: Style manager for text attributes
    ///   - fontProvider: Function to load fonts by size and weight
    init(styleManager: StyleManager, fontProvider: @escaping (CGFloat, NSFont.Weight) -> NSFont) {
        self.styleManager = styleManager
        self.fontProvider = fontProvider
    }

    // MARK: - Background Drawing

    /// Draw the background gradient and vignette.
    /// - Parameters:
    ///   - rect: Drawing rectangle
    ///   - phase: Animation phase for background animation
    func drawBackground(in rect: NSRect, phase: CGFloat) {
        // Background: subtle gradient + vignette
        let topShift = ScreensaverConfiguration.bgTopShiftBase + ScreensaverConfiguration.bgTopShiftAmplitude * sin(phase)
        let bottomShift = ScreensaverConfiguration.bgBottomShiftBase + ScreensaverConfiguration.bgBottomShiftAmplitude * cos(phase * ScreensaverConfiguration.bgBottomPhaseOffset)

        let bgTop = NSColor(
            calibratedRed: ScreensaverConfiguration.bgTopRed + topShift,
            green: ScreensaverConfiguration.bgTopGreen + topShift,
            blue: ScreensaverConfiguration.bgTopBlue + topShift,
            alpha: 1
        )
        let bgBottom = NSColor(
            calibratedRed: ScreensaverConfiguration.bgBottomRed + bottomShift,
            green: ScreensaverConfiguration.bgBottomGreen + bottomShift,
            blue: ScreensaverConfiguration.bgBottomBlue + bottomShift,
            alpha: 1
        )

        let bgGradient = NSGradient(colors: [bgTop, bgBottom]) ?? NSGradient(starting: bgTop, ending: bgBottom)
        bgGradient?.draw(in: rect, angle: 90)

        let vignette = NSGradient(colors: [
            NSColor.black.withAlphaComponent(0.0),
            NSColor.black.withAlphaComponent(ScreensaverConfiguration.vignetteAlpha)
        ])
        vignette?.draw(in: rect, relativeCenterPosition: .zero)
    }

    // MARK: - Glow Drawing

    /// Draw the soft glow behind the center phrase.
    /// - Parameters:
    ///   - center: Center point for the glow
    ///   - radius: Radius of the glow
    func drawGlow(center: CGPoint, radius: CGFloat) {
        let glow = NSGradient(colors: [
            NSColor.white.withAlphaComponent(ScreensaverConfiguration.glowAlpha),
            NSColor.white.withAlphaComponent(0.0)
        ])
        glow?.draw(fromCenter: center, radius: 0, toCenter: center, radius: radius, options: [])
    }

    // MARK: - Center Text Drawing

    /// Draw the center text ("the story").
    /// - Parameters:
    ///   - text: Text to draw
    ///   - metrics: Layout metrics
    ///   - bounds: View bounds
    ///   - isFlipped: Whether the view is flipped
    /// - Returns: Story origin point and baseline Y for alignment
    func drawCenterText(
        _ text: String,
        metrics: Metrics,
        in bounds: NSRect,
        isFlipped: Bool
    ) -> (origin: CGPoint, baselineY: CGFloat, wordRightX: CGFloat) {
        let storyAttrs = styleManager.storyAttributes(metrics: metrics)
        let storySize = (text as NSString).size(withAttributes: storyAttrs)

        let centerX = bounds.midX
        let screenCenterY = bounds.midY

        // Calculate space width for proper spacing between words and "the story"
        let fontBasedSpace = metrics.storyFont.pointSize * ScreensaverConfiguration.fontBasedSpaceMultiplier
        let spaceWidth = fontBasedSpace + ScreensaverConfiguration.fixedSpaceWidth

        // Position "the story" first to determine its baseline
        let storyOrigin = CGPoint(
            x: centerX - storySize.width / 2 + spaceWidth,
            y: screenCenterY - storySize.height / 2 + ScreensaverConfiguration.storyVerticalOffset
        )
        let storyBaselineY = storyOrigin.y + metrics.storyFont.ascender

        // Draw "the story" with phrase-centric positioning
        (text as NSString).draw(at: storyOrigin, withAttributes: storyAttrs)

        // Words are right-aligned to sit nicely before "the story"
        let wordRightX = storyOrigin.x - ScreensaverConfiguration.wordGap

        return (storyOrigin, storyBaselineY, wordRightX)
    }

    // MARK: - Carousel Drawing

    /// Draw the word carousel.
    /// - Parameters:
    ///   - words: Array of words to display
    ///   - metrics: Layout metrics
    ///   - scrollOffset: Current scroll offset
    ///   - bounds: View bounds
    ///   - isFlipped: Whether the view is flipped
    ///   - storyBaselineY: Baseline Y of the story text for alignment
    ///   - wordRightX: Right X position for word alignment
    func drawCarousel(
        words: [String],
        metrics: Metrics,
        scrollOffset: CGFloat,
        in bounds: NSRect,
        isFlipped: Bool,
        storyBaselineY: CGFloat,
        wordRightX: CGFloat
    ) {
        let lineHeight = metrics.lineHeight
        guard lineHeight > 0 else { return }

        // Get the font for the centered word (maximum size: wordBaseSize + wordBoost)
        let centeredWordFont = fontProvider(metrics.wordBaseSize + metrics.wordBoost, .bold)

        // Calculate centerY so that the centered word's baseline aligns with storyBaselineY
        let fontCenterOffset = (centeredWordFont.ascender + abs(centeredWordFont.descender)) / 2
        let centeredWordBaselineOffset = centeredWordFont.ascender - fontCenterOffset
        let centerY = storyBaselineY - centeredWordBaselineOffset
        let baselineOffset = centeredWordBaselineOffset

        // Progress within the word cycle
        let progress = scrollOffset / lineHeight
        let baseIndex = Int(floor(progress)) % words.count
        let t = progress - floor(progress)

        let ySign: CGFloat = isFlipped ? 1 : -1

        for offset in -3...3 {
            // Offsets are visual positions; index mapping keeps list order while moving downward
            let wordIndex = (baseIndex - offset + words.count) % words.count
            // Negative offsets sit above the center line; move linearly downward
            let wordCenterY = centerY + (CGFloat(offset) + t) * lineHeight * ySign

            // Visual treatment: fade + slight size emphasis near center
            let dist = abs(wordCenterY - centerY)
            let maxVisible = lineHeight * ScreensaverConfiguration.wordVisibilityMultiplier

            if dist > maxVisible {
                continue
            }

            // Optimized easing calculation - pre-calculate squared falloff for better performance
            let norm = min(1.0, dist / (lineHeight * ScreensaverConfiguration.wordVisibilityMultiplier))
            let falloff = 1.0 - norm
            let ease = falloff * falloff // Equivalent to pow(falloff, 2.0) but faster

            // Fade-in/out at the edges so the first word appears smoothly
            let edgeInner = lineHeight * ScreensaverConfiguration.edgeFadeInnerMultiplier
            let edgeOuter = maxVisible
            let edgeT = max(0.0, min(1.0, (edgeOuter - dist) / (edgeOuter - edgeInner)))
            let edgeFade = edgeT * edgeT * (3.0 - 2.0 * edgeT)

            // Keep center strong; outer rows are nearly ghosted
            let alpha = (ScreensaverConfiguration.minWordAlpha + ScreensaverConfiguration.maxWordAlpha * ease) * edgeFade
            let fontSize = metrics.wordBaseSize + metrics.wordBoost * ease
            let wordFont = fontProvider(fontSize, .bold)

            let wordAttrs = styleManager.wordAttributes(fontSize: fontSize, alpha: alpha, ease: ease)

            let w = words[wordIndex]
            let wordSize = (w as NSString).size(withAttributes: wordAttrs)

            // Align vertically with "the story" baseline using font metrics
            let wordBaselineY = wordCenterY + baselineOffset
            let wordOrigin = CGPoint(
                x: wordRightX - wordSize.width,
                y: wordBaselineY - wordFont.ascender
            )

            (w as NSString).draw(at: wordOrigin, withAttributes: wordAttrs)
        }
    }

    // MARK: - Logo Drawing

    /// Draw the logo below the carousel.
    /// - Parameters:
    ///   - text: Logo text
    ///   - metrics: Layout metrics
    ///   - bounds: View bounds
    ///   - centerY: Center Y of the carousel
    ///   - lineHeight: Line height for spacing calculations
    func drawLogo(
        text: String,
        metrics: Metrics,
        in bounds: NSRect,
        centerY: CGFloat,
        lineHeight: CGFloat
    ) {
        let fontSize = min(bounds.width, bounds.height) * ScreensaverConfiguration.logoSizeScale
        let logoFont = fontProvider(fontSize, .bold)

        // Create logo attributes (not cached in StyleManager as they depend on bounds)
        let logoAttrs: [NSAttributedString.Key: Any] = [
            .font: logoFont,
            .foregroundColor: NSColor.white.withAlphaComponent(ScreensaverConfiguration.logoTextAlpha),
            .kern: ScreensaverConfiguration.logoTextKern
        ]

        let logoSize = (text as NSString).size(withAttributes: logoAttrs)
        let centerX = bounds.midX

        // Position logo below the carousel
        // Calculate bottom of carousel (lowest visible word position)
        let carouselBottom = centerY - (lineHeight * ScreensaverConfiguration.wordVisibilityMultiplier)
        let logoY = carouselBottom - logoSize.height - (lineHeight * ScreensaverConfiguration.logoSpacingMultiplier)

        let logoOrigin = CGPoint(
            x: centerX - logoSize.width / 2,
            y: logoY
        )

        (text as NSString).draw(at: logoOrigin, withAttributes: logoAttrs)
    }
}
