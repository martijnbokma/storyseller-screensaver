import ScreenSaver
import AppKit
import os.log

/// macOS ScreenSaver: vertical word carousel that forms phrases like
/// "create the story", "develop the story", ... in a continuous loop.
final class StorySellerSaverView: ScreenSaverView {

    // MARK: - Constants (documented magic numbers)

    /// Maximum visibility distance for words as a multiplier of line height.
    /// Words beyond this distance are culled from rendering.
    private static let wordVisibilityMultiplier: CGFloat = 2.8

    /// Edge fade inner boundary as a multiplier of line height.
    /// Words within this distance have full opacity.
    private static let edgeFadeInnerMultiplier: CGFloat = 1.8

    /// Cache cleanup interval in seconds.
    private static let cacheCleanupInterval: Int = 60

    /// Target frame rate for smooth animation.
    private static let targetFrameRate: Double = 60.0

    /// Maximum delta time to prevent large jumps after frame drops.
    private static let maxDeltaTime: CGFloat = 0.05

    // MARK: - Logging

    private static let logger = OSLog(subsystem: "com.creativebusiness.storysellersaver", category: "Screensaver")

    // MARK: - Content

    private let words: [String] = ["create", "develop", "produce", "manage", "sell"]
    private let centerText: String = "the story"

    // MARK: - Animation state

    private var lastTime: TimeInterval = 0
    /// Scroll offset in points within one full cycle (0 ..< cycleHeight).
    private var scrollOffset: CGFloat = 0
    /// Elapsed time accumulator for move + hold timing.
    private var elapsedTime: CGFloat = 0

    // MARK: - Accessibility

    /// Whether to reduce motion for accessibility. Checked once at animation start.
    private var reduceMotion: Bool = false

    // MARK: - Cached attributes for performance

    private var cachedMetrics: (bounds: NSRect, metrics: Metrics)?
    private var cachedStoryAttrs: [NSAttributedString.Key: Any]?
    private var cachedWordAttrsCache: [String: [NSAttributedString.Key: Any]] = [:]

    // MARK: - Tuning

    /// Seconds for the movement between words.
    private let secondsPerWord: CGFloat = 1.2
    /// Seconds each word stays centered before moving on.
    private let holdSecondsPerWord: CGFloat = 0.6
    /// Horizontal gap between the left word and the centered "the story".
    private let wordGap: CGFloat = 8

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / Self.targetFrameRate
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / Self.targetFrameRate
        wantsLayer = true
    }

    override func startAnimation() {
        super.startAnimation()
        lastTime = ProcessInfo.processInfo.systemUptime
        elapsedTime = 0

        // Check accessibility setting at animation start
        reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        if reduceMotion {
            os_log("Reduce motion enabled - using simplified animations", log: Self.logger, type: .info)
        }
    }

    override func animateOneFrame() {
        super.animateOneFrame()

        let now = ProcessInfo.processInfo.systemUptime
        let dt = CGFloat(min(max(now - lastTime, 0.0), Self.maxDeltaTime))
        lastTime = now

        // Periodic cache cleanup to prevent memory bloat
        if Int(now) % Self.cacheCleanupInterval == 0 {
            cachedWordAttrsCache.removeAll(keepingCapacity: true)
            os_log("Cache cleanup performed", log: Self.logger, type: .debug)
        }

        // Compute metrics based on current bounds (handles preview/screen size changes).
        let metrics = computeMetrics()
        let cycleHeight = metrics.lineHeight * CGFloat(words.count)
        guard cycleHeight > 0 else {
            os_log("Invalid cycle height: %{public}f", log: Self.logger, type: .error, cycleHeight)
            setNeedsDisplay(bounds)
            return
        }

        // If reduce motion is enabled, show static centered word
        if reduceMotion {
            scrollOffset = 0
        } else {
            // Move downward with a brief hold at center for each word.
            let moveSeconds = max(0.05, secondsPerWord)
            let holdSeconds = max(0.0, holdSecondsPerWord)
            let wordDuration = moveSeconds + holdSeconds
            let cycleDuration = wordDuration * CGFloat(words.count)

            elapsedTime = (elapsedTime + dt).truncatingRemainder(dividingBy: cycleDuration)
            let wordIndex = Int(floor(elapsedTime / wordDuration)) % words.count
            let localTime = elapsedTime - CGFloat(wordIndex) * wordDuration
            let t: CGFloat
            if localTime <= holdSeconds {
                t = 0
            } else {
                let rawT = min(1.0, (localTime - holdSeconds) / moveSeconds)
                // Smooth easing for more natural movement
                t = rawT < 0.5 ? 2 * rawT * rawT : 1 - pow(-2 * rawT + 2, 2) / 2
            }

            scrollOffset = (CGFloat(wordIndex) + t) * metrics.lineHeight
        }

        setNeedsDisplay(bounds)
    }

    override func draw(_ rect: NSRect) {
        guard NSGraphicsContext.current != nil else {
            os_log("No graphics context available", log: Self.logger, type: .error)
            return
        }

        let metrics: Metrics
        do {
            metrics = computeMetrics()
            // Debug: check if we have valid metrics
            guard metrics.lineHeight > 0 else {
                throw NSError(domain: "Screensaver", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid metrics"])
            }
        } catch {
            os_log("Metrics computation failed: %{public}@", log: Self.logger, type: .error, error.localizedDescription)
            // Fallback rendering for Release mode crashes
            NSColor.black.setFill()
            bounds.fill()
            // Draw a simple text message
            let fallbackText = "StorySeller"
            let font = NSFont.systemFont(ofSize: 24, weight: .regular)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white
            ]
            let textSize = (fallbackText as NSString).size(withAttributes: attrs)
            let textRect = CGRect(
                x: (bounds.width - textSize.width) / 2,
                y: (bounds.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            (fallbackText as NSString).draw(in: textRect, withAttributes: attrs)
            return
        }

        // Background: subtle gradient + vignette
        let phase = (scrollOffset / max(metrics.lineHeight, 1)) * 0.2
        let topShift = 0.02 + 0.01 * sin(phase)
        let bottomShift = 0.01 + 0.01 * cos(phase * 0.9)
        let bgTop = NSColor(calibratedRed: 0.05 + topShift, green: 0.06 + topShift, blue: 0.08 + topShift, alpha: 1)
        let bgBottom = NSColor(calibratedRed: 0.01 + bottomShift, green: 0.02 + bottomShift, blue: 0.03 + bottomShift, alpha: 1)
        let bgGradient = NSGradient(colors: [bgTop, bgBottom]) ?? NSGradient(starting: bgTop, ending: bgBottom)
        bgGradient?.draw(in: bounds, angle: 90)

        let vignette = NSGradient(colors: [
            NSColor.black.withAlphaComponent(0.0),
            NSColor.black.withAlphaComponent(0.45)
        ])
        vignette?.draw(in: bounds, relativeCenterPosition: .zero)

        let centerX = bounds.midX
        let centerY = bounds.midY

        // Attributes for the fixed center text (SF Pro Display look)
        // Cache story attributes for better performance
        let storyAttrs: [NSAttributedString.Key: Any]
        if let cached = cachedStoryAttrs {
            storyAttrs = cached
        } else {
            storyAttrs = [
                .font: metrics.storyFont,
                .foregroundColor: NSColor.white.withAlphaComponent(0.9),
                .kern: -0.2
            ]
            cachedStoryAttrs = storyAttrs
        }

        let storySize = (centerText as NSString).size(withAttributes: storyAttrs)

        // Word carousel geometry
        let lineHeight = metrics.lineHeight
        guard lineHeight > 0 else { return }

        // Progress within the word cycle.
        let progress = scrollOffset / lineHeight
        let baseIndex = Int(floor(progress)) % words.count
        let t = progress - floor(progress)

        // Soft glow behind the phrase
        // Calculate space width for proper spacing between words and "the story"
        // Using font-based calculation for approximately one space character width
        let spaceWidth = metrics.storyFont.pointSize * 0.8 // Space character width for better visual separation
        let storyOrigin = CGPoint(
            x: centerX - storySize.width / 2 + spaceWidth,
            y: centerY - storySize.height / 2
        )
        let storyBaselineY = storyOrigin.y + metrics.storyFont.ascender
        let baselineOffset = storyBaselineY - centerY
        let glowCenter = CGPoint(x: centerX, y: centerY)
        let glow = NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.07),
            NSColor.white.withAlphaComponent(0.0)
        ])
        glow?.draw(fromCenter: glowCenter, radius: 0, toCenter: glowCenter, radius: max(bounds.width, bounds.height) * 0.35, options: [])

        // Draw "the story" with phrase-centric positioning
        (centerText as NSString).draw(at: storyOrigin, withAttributes: storyAttrs)

        // Words are right-aligned to sit nicely before "the story".
        let wordRightX = storyOrigin.x - wordGap

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
            // Extended so incoming words become visible earlier for a smoother loop.
            let maxVisible = lineHeight * Self.wordVisibilityMultiplier
            if dist > maxVisible {
                continue
            }
            // Optimized easing calculation - pre-calculate squared falloff for better performance
            let norm = min(1.0, dist / (lineHeight * Self.wordVisibilityMultiplier))
            let falloff = 1.0 - norm
            let ease = falloff * falloff // Equivalent to pow(falloff, 2.0) but faster

            // Fade-in/out at the edges so the first word appears smoothly.
            let edgeInner = lineHeight * Self.edgeFadeInnerMultiplier
            let edgeOuter = maxVisible
            let edgeT = max(0.0, min(1.0, (edgeOuter - dist) / (edgeOuter - edgeInner)))
            let edgeFade = edgeT * edgeT * (3.0 - 2.0 * edgeT)

            // Keep center strong; outer rows are nearly ghosted.
            let alpha = (0.02 + 0.98 * ease) * edgeFade
            let fontSize = metrics.wordBaseSize + metrics.wordBoost * ease
            let wordFont = preferredFont(size: fontSize, weight: .bold)

            // Cache word attributes for better performance
            // Use integer-based cache key to avoid floating-point precision issues
            let fontSizeKey = Int(fontSize * 100)
            let alphaKey = Int(alpha * 1000)
            let cacheKey = "\(fontSizeKey)-\(alphaKey)"
            let wordAttrs: [NSAttributedString.Key: Any]
            if let cached = cachedWordAttrsCache[cacheKey] {
                wordAttrs = cached
            } else {
                let shadow = NSShadow()
                shadow.shadowOffset = .zero
                shadow.shadowBlurRadius = 16 * ease
                shadow.shadowColor = NSColor.white.withAlphaComponent(0.65 * ease)

                wordAttrs = [
                    .font: wordFont,
                    .foregroundColor: NSColor.white.withAlphaComponent(alpha),
                    .shadow: shadow,
                    .kern: -0.15
                ]
                cachedWordAttrsCache[cacheKey] = wordAttrs
            }

            let w = words[wordIndex]
            let wordSize = (w as NSString).size(withAttributes: wordAttrs)

            // Align vertically with "the story" baseline using font metrics.
            // Align the word baseline to the story baseline, preserving row position.
            let wordBaselineY = wordCenterY + baselineOffset
            let wordOrigin = CGPoint(
                x: wordRightX - wordSize.width,
                y: wordBaselineY - wordFont.ascender
            )

            (w as NSString).draw(at: wordOrigin, withAttributes: wordAttrs)
        }

        // Optional subtle center guide (disabled by default).
        // ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.05).cgColor)
        // ctx.setLineWidth(1)
        // ctx.stroke(CGRect(x: 0, y: centerY, width: bounds.width, height: 1))
    }

    override var hasConfigureSheet: Bool { false }

    // MARK: - Layout / typography

    private struct Metrics {
        var storyFont: NSFont
        var lineHeight: CGFloat
        var wordBaseSize: CGFloat
        var wordBoost: CGFloat
        var activeWordFont: NSFont
    }

    private func computeMetrics() -> Metrics {
        // Cache metrics to avoid recalculation when bounds haven't changed
        if let cached = cachedMetrics, cached.bounds == bounds {
            return cached.metrics
        }

        // Scale typography to screen size but keep it tasteful in preview mode.
        let minDim = max(100, min(bounds.width, bounds.height)) // Ensure minimum screen size

        // Base size tuned for typical screens; clamped so it doesn't explode.
        let base = max(34, min(72, minDim * 0.095))
        let storySize = base
        let wordBase = base * 0.92

        // Slight emphasis at the center word.
        let boost = max(6, storySize * 0.18)

        let storyFont = preferredFont(size: storySize, weight: .regular)
        let activeWordFont = preferredFont(size: wordBase + boost, weight: .semibold)

        // Line height: enough separation to feel like a carousel, not a list.
        let lineHeight = max(52, storySize * 1.16)

        let metrics = Metrics(
            storyFont: storyFont,
            lineHeight: lineHeight,
            wordBaseSize: wordBase,
            wordBoost: boost,
            activeWordFont: activeWordFont
        )

        // Cache the result
        cachedMetrics = (bounds: bounds, metrics: metrics)

        return metrics
    }

    private func preferredFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        // Ensure size is valid
        let safeSize = max(1, size)

        // Try Cera Pro first (primary font)
        // Map NSFont.Weight to Cera Pro variants
        // Try multiple naming conventions as font names can vary
        let ceraProNames: [String]
        switch weight {
        case .thin, .ultraLight:
            ceraProNames = [
                "Cera Pro Thin",
                "CeraPro-Thin",
                "Cera Pro Light",
                "Cera Pro Regular"
            ]
        case .light:
            ceraProNames = [
                "Cera Pro Light",
                "CeraPro-Light",
                "Cera Pro Regular",
                "Cera Pro Medium"
            ]
        case .regular, .medium:
            ceraProNames = [
                "Cera Pro Regular",
                "CeraPro-Regular",
                "Cera Pro",
                "Cera Pro Medium"
            ]
        case .semibold, .bold:
            ceraProNames = [
                "Cera Pro Bold",
                "CeraPro-Bold",
                "Cera Pro Medium",
                "Cera Pro"
            ]
        case .heavy, .black:
            ceraProNames = [
                "Cera Pro Black",
                "CeraPro-Black",
                "Cera Pro Bold",
                "Cera Pro"
            ]
        default:
            ceraProNames = [
                "Cera Pro Regular",
                "CeraPro-Regular",
                "Cera Pro Medium",
                "Cera Pro"
            ]
        }

        for name in ceraProNames {
            if let font = NSFont(name: name, size: safeSize), font.pointSize > 0 {
                return font
            }
        }

        // Fallback to Poppins if Cera Pro not available
        let isBold = weight >= .semibold
        let poppinsNames = isBold
            ? ["Poppins-Bold", "Poppins-SemiBold", "Poppins"]
            : ["Poppins-Regular", "Poppins"]

        for name in poppinsNames {
            if let font = NSFont(name: name, size: safeSize), font.pointSize > 0 {
                return font
            }
        }

        if let avenir = NSFont(name: "Avenir Next", size: safeSize), avenir.pointSize > 0 {
            return avenir
        }
        if let helvetica = NSFont(name: "Helvetica Neue", size: safeSize), helvetica.pointSize > 0 {
            return helvetica
        }

        // Ultimate fallback - system font
        return NSFont.systemFont(ofSize: safeSize, weight: weight)
    }
}
