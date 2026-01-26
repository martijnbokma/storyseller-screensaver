import ScreenSaver
import AppKit
import os.log

/// macOS ScreenSaver: vertical word carousel that forms phrases like
/// "create the story", "develop the story", ... in a continuous loop.
final class StorySellerSaverView: ScreenSaverView {

    // MARK: - Logging

    private static let logger = OSLog(subsystem: "com.creativebusiness.storysellersaver", category: "Screensaver")

    // MARK: - Components

    /// Animation engine for managing timing and state.
    private var animationEngine: AnimationEngine?

    /// Metrics calculator for typography and layout.
    private var metricsCalculator: MetricsCalculator?

    /// Style manager for fonts and attributes.
    private var styleManager: StyleManager?

    /// Renderer for all drawing operations.
    private var renderer: ScreensaverRenderer?

    // MARK: - Animation State

    /// Last frame time for delta calculation.
    private var lastTime: TimeInterval = 0

    /// Current scroll offset from animation engine.
    private var scrollOffset: CGFloat = 0

    // MARK: - Initialization

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / ScreensaverConfiguration.targetFrameRate
        wantsLayer = true
        initializeComponents()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / ScreensaverConfiguration.targetFrameRate
        wantsLayer = true
        initializeComponents()
    }

    // MARK: - Component Initialization

    /// Initialize all component instances.
    private func initializeComponents() {
        let reduceMotion = AccessibilityManager.shouldReduceMotion
        let wordCount = ScreensaverConfiguration.words.count

        // Initialize animation engine
        animationEngine = AnimationEngine(wordCount: wordCount, reduceMotion: reduceMotion)

        // Initialize metrics calculator with font provider
        metricsCalculator = MetricsCalculator(fontProvider: NSFont.preferredFont)

        // Initialize style manager with font provider
        styleManager = StyleManager(fontProvider: NSFont.preferredFont)

        // Initialize renderer
        if let styleManager = styleManager {
            renderer = ScreensaverRenderer(styleManager: styleManager, fontProvider: NSFont.preferredFont)
        }

        if reduceMotion {
            os_log("Reduce motion enabled - using simplified animations", log: Self.logger, type: .info)
        }
    }

    // MARK: - Animation Lifecycle

    override func startAnimation() {
        super.startAnimation()
        lastTime = ProcessInfo.processInfo.systemUptime
        animationEngine?.reset()
    }

    override func animateOneFrame() {
        super.animateOneFrame()

        let now = ProcessInfo.processInfo.systemUptime
        let dt = CGFloat(min(max(now - lastTime, 0.0), ScreensaverConfiguration.maxDeltaTime))
        lastTime = now

        // Periodic cache cleanup to prevent memory bloat
        if Int(now) % ScreensaverConfiguration.cacheCleanupInterval == 0 {
            styleManager?.cleanupCache()
            os_log("Cache cleanup performed", log: Self.logger, type: .debug)
        }

        // Compute metrics based on current bounds (handles preview/screen size changes)
        guard let metricsCalculator = metricsCalculator else {
            os_log("Metrics calculator not initialized", log: Self.logger, type: .error)
            setNeedsDisplay(bounds)
            return
        }

        let metrics = metricsCalculator.computeMetrics(for: bounds, isPreview: isPreview)
        let cycleHeight = metrics.lineHeight * CGFloat(ScreensaverConfiguration.words.count)

        guard cycleHeight > 0 else {
            os_log("Invalid cycle height: %{public}f", log: Self.logger, type: .error, cycleHeight)
            setNeedsDisplay(bounds)
            return
        }

        // Update animation state
        guard let animationEngine = animationEngine else {
            os_log("Animation engine not initialized", log: Self.logger, type: .error)
            setNeedsDisplay(bounds)
            return
        }

        let state = animationEngine.update(deltaTime: dt, lineHeight: metrics.lineHeight)
        scrollOffset = state.scrollOffset

        setNeedsDisplay(bounds)
    }

    // MARK: - Drawing

    override func draw(_ rect: NSRect) {
        guard NSGraphicsContext.current != nil else {
            os_log("No graphics context available", log: Self.logger, type: .error)
            return
        }

        // Compute metrics with error handling
        guard let metricsCalculator = metricsCalculator else {
            drawFallback()
            return
        }

        let metrics: Metrics
        do {
            metrics = metricsCalculator.computeMetrics(for: bounds, isPreview: isPreview)
            guard metrics.lineHeight > 0 else {
                throw ScreensaverError.invalidMetrics("Line height is zero or negative")
            }
        } catch {
            os_log("Metrics computation failed: %{public}@", log: Self.logger, type: .error, error.localizedDescription)
            drawFallback()
            return
        }

        // Get renderer
        guard let renderer = renderer else {
            drawFallback()
            return
        }

        // Calculate background phase
        let phase = (scrollOffset / max(metrics.lineHeight, 1)) * ScreensaverConfiguration.bgPhaseMultiplier

        // Draw background
        renderer.drawBackground(in: bounds, phase: phase)

        // Draw glow
        let centerX = bounds.midX
        let screenCenterY = bounds.midY
        let glowRadius = max(bounds.width, bounds.height) * ScreensaverConfiguration.glowRadiusMultiplier
        renderer.drawGlow(center: CGPoint(x: centerX, y: screenCenterY), radius: glowRadius)

        // Draw center text and get alignment info
        let (storyOrigin, storyBaselineY, wordRightX) = renderer.drawCenterText(
            ScreensaverConfiguration.centerText,
            metrics: metrics,
            in: bounds,
            isFlipped: isFlipped
        )

        // Draw carousel
        renderer.drawCarousel(
            words: ScreensaverConfiguration.words,
            metrics: metrics,
            scrollOffset: scrollOffset,
            in: bounds,
            isFlipped: isFlipped,
            storyBaselineY: storyBaselineY,
            wordRightX: wordRightX
        )

        // Draw logo
        renderer.drawLogo(
            text: ScreensaverConfiguration.logoText,
            metrics: metrics,
            in: bounds,
            centerY: screenCenterY,
            lineHeight: metrics.lineHeight
        )
    }

    // MARK: - Fallback Rendering

    /// Draw fallback content when rendering fails.
    private func drawFallback() {
        NSColor.black.setFill()
        bounds.fill()

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
    }

    override var hasConfigureSheet: Bool { false }
}
