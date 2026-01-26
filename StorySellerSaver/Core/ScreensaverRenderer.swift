import AppKit

/// Handles all drawing operations for the screensaver
final class ScreensaverRenderer {
    // MARK: - Background Drawing

    /// Draws the background gradient and vignette
    /// - Parameters:
    ///   - rect: The drawing rect
    ///   - phase: Animation phase for subtle movement
    func drawBackground(in rect: NSRect, phase: CGFloat) {
        // Background: subtle gradient + vignette
        let topShift = 0.02 + 0.01 * sin(phase)
        let bottomShift = 0.01 + 0.01 * cos(phase * 0.9)
        let bgTop = NSColor(
            calibratedRed: 0.05 + topShift,
            green: 0.06 + topShift,
            blue: 0.08 + topShift,
            alpha: 1
        )
        let bgBottom = NSColor(
            calibratedRed: 0.01 + bottomShift,
            green: 0.02 + bottomShift,
            blue: 0.03 + bottomShift,
            alpha: 1
        )
        let bgGradient = NSGradient(colors: [bgTop, bgBottom]) ?? NSGradient(starting: bgTop, ending: bgBottom)
        bgGradient?.draw(in: rect, angle: 90)

        let vignette = NSGradient(colors: [
            NSColor.black.withAlphaComponent(0.0),
            NSColor.black.withAlphaComponent(0.45)
        ])
        vignette?.draw(in: rect, relativeCenterPosition: .zero)
    }

    // MARK: - Center Text Drawing

    /// Draws the center text ("the story")
    /// - Parameters:
    ///   - text: The text to draw
    ///   - metrics: Current metrics
    ///   - bounds: View bounds
    ///   - attributes: Text attributes
    /// - Returns: The baseline Y position and origin point
    func drawCenterText(
        _ text: String,
        metrics: Metrics,
        bounds: NSRect,
        attributes: [NSAttributedString.Key: Any]
    ) -> (baselineY: CGFloat, origin: CGPoint) {
        let centerX = bounds.midX
        let screenCenterY = bounds.midY

        let storySize = (text as NSString).size(withAttributes: attributes)

        // Calculate space width for proper spacing between words and "the story"
        let fontBasedSpace = metrics.storyFont.pointSize * 1.3
        let fixedSpace: CGFloat = 25
        let spaceWidth = fontBasedSpace + fixedSpace

        // Position "the story" first to determine its baseline
        let storyVerticalOffset: CGFloat = 8.0
        let storyOrigin = CGPoint(
            x: centerX - storySize.width / 2 + spaceWidth,
            y: screenCenterY - storySize.height / 2 + storyVerticalOffset
        )
        let storyBaselineY = storyOrigin.y + metrics.storyFont.ascender

        // Draw soft glow behind the phrase
        let glowCenter = CGPoint(x: centerX, y: screenCenterY)
        let glow = NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.07),
            NSColor.white.withAlphaComponent(0.0)
        ])
        glow?.draw(
            fromCenter: glowCenter,
            radius: 0,
            toCenter: glowCenter,
            radius: max(bounds.width, bounds.height) * 0.35,
            options: []
        )

        // Draw "the story"
        (text as NSString).draw(at: storyOrigin, withAttributes: attributes)

        return (baselineY: storyBaselineY, origin: storyOrigin)
    }

    // MARK: - Carousel Drawing

    /// Draws the word carousel
    /// - Parameters:
    ///   - words: Array of words to display
    ///   - metrics: Current metrics
    ///   - state: Current animation state
    ///   - bounds: View bounds
    ///   - centerY: Center Y position of the carousel
    ///   - baselineOffset: Baseline offset for aligning words with center text
    ///   - storyOrigin: Origin point of the center text
    ///   - isFlipped: Whether the view is flipped
    ///   - wordAttributesProvider: Function to get word attributes
    func drawCarousel(
        words: [String],
        metrics: Metrics,
        state: AnimationState,
        bounds: NSRect,
        centerY: CGFloat,
        baselineOffset: CGFloat,
        storyOrigin: CGPoint,
        isFlipped: Bool,
        wordAttributesProvider: (CGFloat, CGFloat, CGFloat) -> [NSAttributedString.Key: Any]
    ) {
        let lineHeight = metrics.lineHeight
        guard lineHeight > 0 else { return }

        // Word carousel geometry
        let progress = state.scrollOffset / lineHeight
        let baseIndex = Int(floor(progress)) % words.count
        let t = progress - floor(progress)

        // Words are right-aligned to sit nicely before "the story"
        let wordRightX = storyOrigin.x - ScreensaverConfiguration.wordGap

        // Positioning rule:
        // - Only 5 words are visible (2 above, 1 center, 2 below).
        // - As scrollOffset increases by lineHeight, the next word becomes centered.
        let ySign: CGFloat = isFlipped ? 1 : -1
        for offset in -3...3 {
            // Offsets are visual positions; index mapping keeps list order while moving downward.
            let wordIndex = (baseIndex - offset + words.count) % words.count
            // Negative offsets sit above the center line; move linearly downward.
            let wordCenterY = centerY + (CGFloat(offset) + t) * lineHeight * ySign

            // Visual treatment: fade + slight size emphasis near center
            let dist = abs(wordCenterY - centerY)
            // Hard cull to avoid a third row peeking in below/above.
            let maxVisible = lineHeight * ScreensaverConfiguration.wordVisibilityMultiplier
            if dist > maxVisible {
                continue
            }

            // Optimized easing calculation
            let norm = min(1.0, dist / (lineHeight * ScreensaverConfiguration.wordVisibilityMultiplier))
            let falloff = 1.0 - norm
            let ease = falloff * falloff

            // Fade-in/out at the edges so the first word appears smoothly.
            let edgeInner = lineHeight * ScreensaverConfiguration.edgeFadeInnerMultiplier
            let edgeOuter = maxVisible
            let edgeT = max(0.0, min(1.0, (edgeOuter - dist) / (edgeOuter - edgeInner)))
            let edgeFade = edgeT * edgeT * (3.0 - 2.0 * edgeT)

            // Keep center strong; outer rows are nearly ghosted.
            let alpha = (0.02 + 0.98 * ease) * edgeFade
            let fontSize = metrics.wordBaseSize + metrics.wordBoost * ease

            let wordAttrs = wordAttributesProvider(fontSize, alpha, ease)
            let w = words[wordIndex]
            let wordSize = (w as NSString).size(withAttributes: wordAttrs)

            // Get font from attributes for baseline calculation
            guard let font = wordAttrs[.font] as? NSFont else { continue }

            // Align vertically with "the story" baseline using font metrics.
            let wordBaselineY = wordCenterY + baselineOffset
            let wordOrigin = CGPoint(
                x: wordRightX - wordSize.width,
                y: wordBaselineY - font.ascender
            )

            (w as NSString).draw(at: wordOrigin, withAttributes: wordAttrs)
        }
    }

    // MARK: - Logo Drawing

    /// Draws the logo below the carousel
    /// - Parameters:
    ///   - text: Logo text
    ///   - metrics: Current metrics
    ///   - bounds: View bounds
    ///   - centerY: Center Y of the carousel
    ///   - attributes: Logo text attributes
    func drawLogo(
        text: String,
        metrics: Metrics,
        bounds: NSRect,
        centerY: CGFloat,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let logoSize = (text as NSString).size(withAttributes: attributes)
        let centerX = bounds.midX

        // Position logo below the carousel
        let carouselBottom = centerY - (metrics.lineHeight * ScreensaverConfiguration.wordVisibilityMultiplier)
        let logoY = carouselBottom - logoSize.height - (metrics.lineHeight * ScreensaverConfiguration.logoSpacingMultiplier)

        let logoOrigin = CGPoint(
            x: centerX - logoSize.width / 2,
            y: logoY
        )

        (text as NSString).draw(at: logoOrigin, withAttributes: attributes)
    }

    // MARK: - Fallback Drawing

    /// Draws a fallback view when rendering fails
    /// - Parameters:
    ///   - bounds: View bounds
    ///   - message: Error message to display
    func drawFallback(in bounds: NSRect, message: String = "StorySeller") {
        NSColor.black.setFill()
        bounds.fill()

        let font = NSFont.systemFont(ofSize: 24, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        let textSize = (message as NSString).size(withAttributes: attrs)
        let textRect = CGRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        (message as NSString).draw(in: textRect, withAttributes: attrs)
    }
}
