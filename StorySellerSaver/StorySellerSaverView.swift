import ScreenSaver
import AppKit
import os.log

/// macOS ScreenSaver: vertical word carousel that forms phrases like
/// "create the story", "develop the story", ... in a continuous loop.
final class StorySellerSaverView: ScreenSaverView {
    // MARK: - Logging

    private static let logger = OSLog(
        subsystem: "com.creativebusiness.storysellersaver",
        category: "Screensaver"
    )

    // MARK: - Components

    private let animationEngine: AnimationEngine
    private let metricsCalculator = MetricsCalculator()
    private let styleManager = StyleManager()
    private let renderer = ScreensaverRenderer()

    // MARK: - Animation State

    private var lastTime: TimeInterval = 0
    private var currentAnimationState: AnimationState?

    // MARK: - Accessibility

    private var reduceMotion: Bool = false

    // MARK: - Initialization

    override init?(frame: NSRect, isPreview: Bool) {
        // Initialize with default reduceMotion (will be updated in startAnimation)
        self.animationEngine = AnimationEngine(reduceMotion: false)
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / ScreensaverConfiguration.targetFrameRate
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        self.animationEngine = AnimationEngine(reduceMotion: false)
        super.init(coder: coder)
        animationTimeInterval = 1.0 / ScreensaverConfiguration.targetFrameRate
        wantsLayer = true
    }

    // MARK: - Lifecycle

    override func startAnimation() {
        super.startAnimation()
        lastTime = ProcessInfo.processInfo.systemUptime

        // Check accessibility setting at animation start
        reduceMotion = AccessibilityManager.shouldReduceMotion

        // Recreate animation engine with correct reduceMotion setting
        // Note: We can't mutate the let property, so we'll handle this in update
        if reduceMotion {
            os_log("Reduce motion enabled - using simplified animations", log: Self.logger, type: .info)
        }

        animationEngine.reset()
    }

    override func animateOneFrame() {
        super.animateOneFrame()

        let now = ProcessInfo.processInfo.systemUptime
        let dt = CGFloat(min(max(now - lastTime, 0.0), ScreensaverConfiguration.maxDeltaTime))
        lastTime = now

        // Periodic cache cleanup to prevent memory bloat
        if Int(now) % ScreensaverConfiguration.cacheCleanupInterval == 0 {
            styleManager.cleanupCache()
            os_log("Cache cleanup performed", log: Self.logger, type: .debug)
        }

        // Compute metrics based on current bounds (handles preview/screen size changes)
        let metrics = metricsCalculator.computeMetrics(
            for: bounds,
            isPreview: isPreview,
            fontProvider: styleManager.preferredFont
        )

        let cycleHeight = metrics.lineHeight * CGFloat(ScreensaverConfiguration.words.count)
        guard cycleHeight > 0 else {
            os_log("Invalid cycle height: %{public}f", log: Self.logger, type: .error, cycleHeight)
            setNeedsDisplay(bounds)
            return
        }

        // Update animation state
        let effectiveReduceMotion = reduceMotion || AccessibilityManager.shouldReduceMotion
        currentAnimationState = animationEngine.update(
            deltaTime: dt,
            wordCount: ScreensaverConfiguration.words.count,
            lineHeight: metrics.lineHeight,
            reduceMotion: effectiveReduceMotion
        )

        setNeedsDisplay(bounds)
    }

    override func draw(_ rect: NSRect) {
        guard NSGraphicsContext.current != nil else {
            os_log("No graphics context available", log: Self.logger, type: .error)
            renderer.drawFallback(in: bounds)
            return
        }

        guard let animationState = currentAnimationState else {
            renderer.drawFallback(in: bounds)
            return
        }

        // Compute metrics
        let metrics: Metrics
        do {
            metrics = metricsCalculator.computeMetrics(
                for: bounds,
                isPreview: isPreview,
                fontProvider: styleManager.preferredFont
            )
            guard metrics.lineHeight > 0 else {
                throw ScreensaverError.invalidMetrics("Line height must be greater than 0")
            }
        } catch {
            os_log("Metrics computation failed: %{public}@", log: Self.logger, type: .error, error.localizedDescription)
            renderer.drawFallback(in: bounds)
            return
        }

        // Draw background with subtle animation
        let phase = (animationState.scrollOffset / max(metrics.lineHeight, 1)) * 0.2
        renderer.drawBackground(in: bounds, phase: phase)

        // Get story attributes
        let storyAttrs = styleManager.storyAttributes(
            metrics: metrics,
            fontProvider: styleManager.preferredFont
        )

        // Draw center text and get baseline info
        let (storyBaselineY, storyOrigin) = renderer.drawCenterText(
            ScreensaverConfiguration.centerText,
            metrics: metrics,
            bounds: bounds,
            attributes: storyAttrs
        )

        // Calculate carousel center Y and baseline offset for alignment
        let centeredWordFont = styleManager.preferredFont(
            size: metrics.wordBaseSize + metrics.wordBoost,
            weight: .bold
        )
        let fontCenterOffset = (centeredWordFont.ascender + abs(centeredWordFont.descender)) / 2
        let centeredWordBaselineOffset = centeredWordFont.ascender - fontCenterOffset
        let carouselCenterY = storyBaselineY - centeredWordBaselineOffset

        // Draw carousel
        renderer.drawCarousel(
            words: ScreensaverConfiguration.words,
            metrics: metrics,
            state: animationState,
            bounds: bounds,
            centerY: carouselCenterY,
            baselineOffset: centeredWordBaselineOffset,
            storyOrigin: storyOrigin,
            isFlipped: isFlipped,
            wordAttributesProvider: { [weak self] fontSize, alpha, ease in
                guard let self = self else {
                    return [:]
                }
                return self.styleManager.wordAttributes(
                    fontSize: fontSize,
                    alpha: alpha,
                    ease: ease,
                    fontProvider: self.styleManager.preferredFont
                )
            }
        )

        // Draw logo
        let logoFontSize = min(bounds.width, bounds.height) * ScreensaverConfiguration.logoSizeScale
        let logoAttrs = styleManager.logoAttributes(
            fontSize: logoFontSize,
            fontProvider: styleManager.preferredFont
        )
        renderer.drawLogo(
            text: ScreensaverConfiguration.logoText,
            metrics: metrics,
            bounds: bounds,
            centerY: carouselCenterY,
            attributes: logoAttrs
        )
    }

    override var hasConfigureSheet: Bool { false }
}
