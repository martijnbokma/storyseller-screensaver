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
            t = min(1.0, (localTime - holdSeconds) / moveSeconds)
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
        let storyAttrs: [NSAttributedString.Key: Any] = [
            .font: metrics.storyFont,
            .foregroundColor: NSColor.white.withAlphaComponent(0.9),
            .kern: -0.2
        ]

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
        for offset in -2...2 {
            // Offsets are visual positions; index mapping keeps list order while moving downward.
            let wordIndex = (baseIndex - offset + words.count) % words.count
            // Negative offsets sit above the center line; move linearly downward.
            let wordCenterY = centerY + (CGFloat(offset) + t) * lineHeight * ySign

            // Visual treatment: fade + slight size emphasis near center
            let dist = abs(wordCenterY - centerY)
            // Hard cull to avoid a third row peeking in below/above.
            if dist > lineHeight * 2.05 {
                continue
            }
            let norm = min(1.0, dist / (lineHeight * 2.0))
            let falloff = 1.0 - norm
            let ease = pow(falloff, 3.1)

            // Keep center strong; outer rows are nearly ghosted.
            let alpha = 0.03 + 0.97 * ease
            let fontSize = metrics.wordBaseSize + metrics.wordBoost * ease
            let wordFont = NSFont.systemFont(ofSize: fontSize, weight: .semibold)

            let shadow = NSShadow()
            shadow.shadowOffset = .zero
            shadow.shadowBlurRadius = 16 * ease
            shadow.shadowColor = NSColor.white.withAlphaComponent(0.65 * ease)

            let wordAttrs: [NSAttributedString.Key: Any] = [
                .font: wordFont,
                .foregroundColor: NSColor.white.withAlphaComponent(alpha),
                .shadow: shadow,
                .kern: -0.15
            ]

            let w = words[wordIndex]
            let wordSize = (w as NSString).size(withAttributes: wordAttrs)

            // Align vertically with "the story" baseline by centering the rects.
            let wordOrigin = CGPoint(
                x: wordRightX - wordSize.width,
                y: wordCenterY - wordSize.height / 2
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
        // Scale typography to screen size but keep it tasteful in preview mode.
        let minDim = min(bounds.width, bounds.height)

        // Base size tuned for typical screens; clamped so it doesn't explode.
        let base = max(34, min(72, minDim * 0.095))
        let storySize = base
        let wordBase = base * 0.92

        // Slight emphasis at the center word.
        let boost = max(6, storySize * 0.18)

        let storyFont = NSFont.systemFont(ofSize: storySize, weight: .regular)
        let activeWordFont = NSFont.systemFont(ofSize: wordBase + boost, weight: .semibold)

        // Line height: enough separation to feel like a carousel, not a list.
        let lineHeight = max(52, storySize * 1.16)

        return Metrics(
            storyFont: storyFont,
            lineHeight: lineHeight,
            wordBaseSize: wordBase,
            wordBoost: boost,
            activeWordFont: activeWordFont
        )
    }
}
