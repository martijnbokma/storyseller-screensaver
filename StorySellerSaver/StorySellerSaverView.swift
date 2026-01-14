import ScreenSaver
import AppKit

/// macOS ScreenSaver: vertical word carousel that forms phrases like
/// "create the story", "develop the story", ... in a continuous loop.
final class StorySellerSaverView: ScreenSaverView {

    // MARK: - Content

    private let words: [String] = ["create", "develop", "produce", "manage", "sell"]
    private let centerText: String = "the story"

    // MARK: - Animation state

    private var lastTime: TimeInterval = 0
    /// Scroll offset in points within one full cycle (0 ..< cycleHeight).
    private var scrollOffset: CGFloat = 0
    /// Elapsed time accumulator for move + hold timing.
    private var elapsedTime: CGFloat = 0

    // MARK: - Cached attributes for performance

    private var cachedMetrics: (bounds: NSRect, metrics: Metrics)?
    private var cachedStoryAttrs: [NSAttributedString.Key: Any]?
    private var cachedWordAttrsCache: [String: [NSAttributedString.Key: Any]] = [:]
    private var cachedBackgroundPhase: CGFloat?

    // MARK: - Tuning

    /// Seconds for the movement between words.
    private let secondsPerWord: CGFloat = 1.2
    /// Seconds each word stays centered before moving on.
    private let holdSecondsPerWord: CGFloat = 0.6
    /// Horizontal gap between the left word and the centered "the story".
    private let wordGap: CGFloat = 18

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 60.0
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 60.0
        wantsLayer = true
    }

    override func startAnimation() {
        super.startAnimation()
        lastTime = ProcessInfo.processInfo.systemUptime
        elapsedTime = 0
    }

    override func animateOneFrame() {
        super.animateOneFrame()

        let now = ProcessInfo.processInfo.systemUptime
        let dt = CGFloat(min(max(now - lastTime, 0.0), 0.05))
        lastTime = now

        // Periodic cache cleanup to prevent memory bloat
        if Int(now) % 60 == 0 { // Every minute
            cachedWordAttrsCache.removeAll(keepingCapacity: true)
        }

        // Compute metrics based on current bounds (handles preview/screen size changes).
        let metrics = computeMetrics()
        let cycleHeight = metrics.lineHeight * CGFloat(words.count)
        guard cycleHeight > 0 else {
            setNeedsDisplay(bounds)
            return
        }

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

        setNeedsDisplay(bounds)
    }

    override func draw(_ rect: NSRect) {
        guard NSGraphicsContext.current != nil else { return }

        let metrics = computeMetrics()

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
        let storyOrigin = CGPoint(
            x: centerX - storySize.width / 2,
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
            let maxVisible = lineHeight * 2.8
            if dist > maxVisible {
                continue
            }
            // Optimized easing calculation - pre-calculate squared falloff for better performance
            let norm = min(1.0, dist / (lineHeight * 2.8))
            let falloff = 1.0 - norm
            let ease = falloff * falloff // Equivalent to pow(falloff, 2.0) but faster

            // Fade-in/out at the edges so the first word appears smoothly.
            let edgeInner = lineHeight * 1.8
            let edgeOuter = maxVisible
            let edgeT = max(0.0, min(1.0, (edgeOuter - dist) / (edgeOuter - edgeInner)))
            let edgeFade = edgeT * edgeT * (3.0 - 2.0 * edgeT)

            // Keep center strong; outer rows are nearly ghosted.
            let alpha = (0.02 + 0.98 * ease) * edgeFade
            let fontSize = metrics.wordBaseSize + metrics.wordBoost * ease
            let wordFont = preferredFont(size: fontSize, weight: .bold)

            // Cache word attributes for better performance
            let cacheKey = "\(fontSize)-\(alpha)"
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
        let minDim = min(bounds.width, bounds.height)

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
        let isBold = weight >= .semibold
        let poppinsNames = isBold
            ? ["Poppins-Bold", "Poppins-SemiBold", "Poppins"]
            : ["Poppins-Regular", "Poppins"]

        for name in poppinsNames {
            if let font = NSFont(name: name, size: size) {
                return font
            }
        }

        if let avenir = NSFont(name: "Avenir Next", size: size) {
            return avenir
        }
        if let helvetica = NSFont(name: "Helvetica Neue", size: size) {
            return helvetica
        }
        return NSFont.systemFont(ofSize: size, weight: weight)
    }
}
