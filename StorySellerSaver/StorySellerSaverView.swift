import AppKit
import QuartzCore
import ScreenSaver

/// StorySellerSaverView - macOS ScreenSaver
///
/// Displays a dynamic vertical carousel of action words that form meaningful phrases
/// with the centered text "the story". The animation creates phrases like:
/// - "create the story"
/// - "develop the story"
/// - "produce the story"
/// - "manage the story"
/// - "sell the story"
///
/// Features:
/// - Smooth vertical scrolling animation with easing
/// - Responsive typography that scales to screen size
/// - Accessibility support (respects reduce motion settings)
/// - Performance optimized with layer-based rendering and caching
/// - Cross-platform font fallbacks for reliability
///
/// Architecture:
/// - Modular design with separate managers for animation, caching, typography, and layers
/// - Protocol-based architecture for testability and maintainability
/// - Comprehensive error handling and validation
/// - Constants-based configuration for easy tuning
final class StorySellerSaverView: ScreenSaverView {

    // MARK: - Protocols

    /// Protocol for managing animation state and timing calculations.
    /// Provides a clean interface for animation logic that can be easily tested and replaced.
    protocol AnimationManaging {
        /// Initializes animation state for a new animation cycle.
        func startAnimation()

        /// Updates animation state based on time delta and returns the current scroll offset.
        /// - Parameters:
        ///   - deltaTime: Time elapsed since last frame in seconds
        ///   - metrics: Current typography metrics
        ///   - wordCount: Total number of words in the carousel
        /// - Returns: Current scroll offset for positioning elements
        func updateAnimationState(deltaTime: CGFloat, metrics: Metrics, wordCount: Int) -> CGFloat

        /// Calculates the time delta since the last animation frame.
        /// - Returns: Time elapsed in seconds, clamped to prevent large jumps
        func calculateDeltaTime() -> CGFloat
    }

    /// Protocol for managing various caches to improve performance.
    /// Centralizes caching logic for fonts, sizes, and rendered images.
    protocol CacheManaging {
        /// Retrieves a cached font or creates and caches a new one.
        /// - Parameters:
        ///   - size: Font size in points
        ///   - weight: Font weight
        ///   - fontSelector: Closure that creates the font if not cached
        /// - Returns: The cached or newly created font
        func cachedFont(size: CGFloat, weight: NSFont.Weight, fontSelector: (CGFloat, NSFont.Weight) -> NSFont) -> NSFont

        /// Retrieves cached text size or calculates and caches a new one.
        /// - Parameters:
        ///   - word: Text to measure
        ///   - font: Font to use for measurement
        ///   - attrs: Additional text attributes
        /// - Returns: Size of the text when rendered
        func cachedSize(for word: String, font: NSFont, attrs: [NSAttributedString.Key: Any]) -> CGSize

        /// Retrieves a cached word image or generates and caches a new one.
        /// - Parameters:
        ///   - word: Word to render
        ///   - font: Font to use for rendering
        ///   - imageGenerator: Closure that creates the image if not cached
        /// - Returns: The cached or newly rendered image
        func cachedWordImage(for word: String, font: NSFont, imageGenerator: (String, NSFont) -> NSImage) -> NSImage
    }

    /// Protocol for typography management including font selection and text metrics.
    /// Handles font fallback logic and responsive typography calculations.
    protocol TypographyManaging {
        /// Selects the best available font with fallback logic.
        /// - Parameters:
        ///   - size: Desired font size
        ///   - weight: Desired font weight
        /// - Returns: Best available font matching the criteria
        func preferredFont(size: CGFloat, weight: NSFont.Weight) -> NSFont

        /// Selects the best available logo font with specialized fallback logic.
        /// - Parameters:
        ///   - size: Desired font size
        ///   - weight: Desired font weight
        /// - Returns: Best available logo font
        func preferredLogoFont(size: CGFloat, weight: NSFont.Weight) -> NSFont

        /// Calculates typography metrics based on screen bounds.
        /// - Parameters:
        ///   - bounds: Available screen bounds
        ///   - isPreview: Whether running in preview mode
        /// - Returns: Complete typography metrics for the current context
        func computeMetrics(for bounds: CGRect, isPreview: Bool) -> Metrics

        /// Quantizes a value to reduce font size variations and improve cache efficiency.
        /// - Parameters:
        ///   - value: Value to quantize
        ///   - step: Quantization step size
        /// - Returns: Quantized value
        func quantize(_ value: CGFloat, step: CGFloat) -> CGFloat

        /// Aligns a value to pixel boundaries for crisp rendering.
        /// - Parameters:
        ///   - value: Value to align
        ///   - scale: Screen scale factor
        /// - Returns: Pixel-aligned value
        func alignToPixel(_ value: CGFloat, scale: CGFloat) -> CGFloat
    }

    /// Protocol for managing Core Animation layers.
    /// Handles layer setup, configuration, and lifecycle management.
    protocol LayerManaging {
        /// Sets up the basic layer hierarchy for rendering.
        /// - Parameters:
        ///   - rootLayer: Root CALayer to configure
        ///   - bounds: Current view bounds
        ///   - isFlipped: Whether the coordinate system is flipped
        func setupLayersIfNeeded(rootLayer: CALayer, bounds: CGRect, isFlipped: Bool)

        /// Sets up layers that require animation.
        /// - Parameter rootLayer: Root CALayer to add animated layers to
        func setupAnimatedLayersIfNeeded(rootLayer: CALayer)
    }

    // MARK: - Animation Manager

    /// Manages animation state and timing for the word carousel.
    /// Handles smooth transitions between words with proper easing and accessibility support.
    private final class AnimationManager: AnimationManaging {
        private var lastTime: TimeInterval = 0
        private var scrollOffset: CGFloat = 0
        private var elapsedInStep: CGFloat = 0
        private var stepIndex: Int = 0

        func startAnimation() {
            lastTime = ProcessInfo.processInfo.systemUptime
            scrollOffset = 0
            elapsedInStep = 0
            stepIndex = 0
        }

        func updateAnimationState(deltaTime: CGFloat, metrics: Metrics, wordCount: Int) -> CGFloat {
            let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            let motionScale: CGFloat = reduceMotion ? Constants.reduceMotionScale : 1.0
            let scaledDeltaTime = reduceMotion ? deltaTime * Constants.reduceMotionDeltaMultiplier : deltaTime
            let moveSeconds = max(0.05, Constants.secondsPerWord * motionScale)
            let holdSeconds = max(0.0, Constants.holdSecondsPerStep * motionScale)
            let stepDuration = moveSeconds + holdSeconds
            elapsedInStep += scaledDeltaTime
            while elapsedInStep >= stepDuration {
                elapsedInStep -= stepDuration
                stepIndex = (stepIndex + 1) % max(wordCount, 1)
            }
            let stepProgress: CGFloat
            if moveSeconds <= 0 || elapsedInStep >= moveSeconds {
                stepProgress = 1.0
            } else {
                stepProgress = elapsedInStep / moveSeconds
            }
            scrollOffset = (CGFloat(stepIndex) + stepProgress) * metrics.lineHeight
            return scrollOffset
        }

        func calculateDeltaTime() -> CGFloat {
            let currentTime = ProcessInfo.processInfo.systemUptime
            let deltaTime = CGFloat(min(max(currentTime - lastTime, 0.0), Constants.maxDeltaTime))
            lastTime = currentTime
            return deltaTime
        }
    }

    // MARK: - Cache Manager

    /// Centralizes caching for fonts, text sizes, and rendered images.
    /// Improves performance by avoiding redundant calculations and rendering operations.
    private final class CacheManager: CacheManaging {
        private var fontCache: [String: NSFont] = [:]
        private var sizeCache: [String: CGSize] = [:]
        private var wordImageCache: [String: NSImage] = [:]

        // MARK: - Font Caching

        func cachedFont(size: CGFloat, weight: NSFont.Weight, fontSelector: (CGFloat, NSFont.Weight) -> NSFont) -> NSFont {
            let key = "\(size)|\(weight.rawValue)"
            if let cached = fontCache[key] {
                return cached
            }
            let font = fontSelector(size, weight)
            fontCache[key] = font
            return font
        }

        // MARK: - Size Caching

        func cachedSize(for word: String, font: NSFont, attrs: [NSAttributedString.Key: Any]) -> CGSize {
            let key = "\(word)|\(font.fontName)|\(font.pointSize)"
            if let cached = sizeCache[key] {
                return cached
            }
            let size = (word as NSString).size(withAttributes: attrs)
            sizeCache[key] = size
            return size
        }

        // MARK: - Image Caching

        func cachedWordImage(for word: String, font: NSFont, imageGenerator: (String, NSFont) -> NSImage) -> NSImage {
            let key = "\(word)|\(font.fontName)|\(font.pointSize)"
            if let cached = wordImageCache[key] {
                return cached
            }

            let image = imageGenerator(word, font)
            // Validate the generated image
            guard image.size.width > 0 && image.size.height > 0 else {
                #if DEBUG
                print("Generated invalid image for word '\(word)' with font \(font.fontName)")
                #endif
                // Return a minimal fallback image
                let fallbackSize = NSSize(width: max(1, font.pointSize * 0.6), height: max(1, font.ascender - font.descender))
                let fallbackImage = NSImage(size: fallbackSize)
                return fallbackImage
            }

            wordImageCache[key] = image
            return image
        }

        // MARK: - Cache Management

        func clearAllCaches() {
            fontCache.removeAll()
            sizeCache.removeAll()
            wordImageCache.removeAll()
        }
    }

    // MARK: - Typography Manager

    /// Handles font selection, fallback logic, and responsive typography calculations.
    /// Ensures consistent text rendering across different screen sizes and configurations.
    private final class TypographyManager: TypographyManaging {
        // MARK: - Font Selection

        func preferredFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
            guard size > 0 else {
                return NSFont.systemFont(ofSize: max(size, 12.0), weight: weight)
            }

            let isBold = weight >= .semibold
            let poppinsNames = isBold
                ? ["Poppins-Bold", "Poppins-SemiBold", "Poppins"]
                : ["Poppins-Regular", "Poppins"]

            for name in poppinsNames {
                if let font = NSFont(name: name, size: size) {
                    return font
                }
            }

            // Fallback fonts
            if let avenir = NSFont(name: "Avenir Next", size: size) {
                return avenir
            }
            if let helvetica = NSFont(name: "Helvetica Neue", size: size) {
                return helvetica
            }

            // Ultimate fallback
            return NSFont.systemFont(ofSize: size, weight: weight)
        }

        func preferredLogoFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
            let isBold = weight >= .bold
            let ceraNames = isBold
                ? ["CeraPro-Black", "CeraPro-Bold", "Cera Pro Black", "Cera Pro Bold", "Cera Pro"]
                : ["CeraPro-Regular", "Cera Pro", "Cera Pro Regular"]
            for name in ceraNames {
                if let font = NSFont(name: name, size: size) {
                    return font
                }
            }
            return preferredFont(size: size, weight: weight)
        }

        // MARK: - Text Metrics

        func computeMetrics(for bounds: CGRect, isPreview: Bool) -> Metrics {
            // Scale typography to screen size but keep it tasteful in preview mode.
            let minDim = min(bounds.width, bounds.height)

            // Base size tuned for typical screens; clamped so it doesn't explode.
            let base = max(Constants.minFontSize, min(Constants.maxFontSize, minDim * Constants.fontSizeScale))
            let storySize = base
            let wordBase = base * Constants.wordFontScale
            let quantizedWordBase = quantize(wordBase, step: 0.5)

            // Slight emphasis at the center word.
            let boost = max(Constants.minFontBoost, storySize * Constants.fontBoostScale)
            let quantizedBoostedSize = quantize(wordBase + boost, step: 0.5)

            let storyFont = preferredFont(size: storySize, weight: .regular)
            let baseWordFont = preferredFont(size: quantizedWordBase, weight: .bold)
            let boostedWordFont = preferredFont(size: quantizedBoostedSize, weight: .bold)
            let activeWordFont = preferredFont(size: quantizedBoostedSize, weight: .semibold)

            // Line height is based on the word font metrics so each step is one true interline.
            let baseAttrs: [NSAttributedString.Key: Any] = [
                .font: baseWordFont,
                .kern: Constants.wordKerning,
            ]
            let boostedAttrs: [NSAttributedString.Key: Any] = [
                .font: boostedWordFont,
                .kern: Constants.wordKerning,
            ]
            let baseHeight = ("Hg" as NSString).size(withAttributes: baseAttrs).height
            let boostedHeight = ("Hg" as NSString).size(withAttributes: boostedAttrs).height
            let baseLineHeight = max(baseHeight, baseWordFont.ascender - baseWordFont.descender + baseWordFont.leading)
            let boostedLineHeight = max(boostedHeight, boostedWordFont.ascender - boostedWordFont.descender + boostedWordFont.leading)
            let rawWordLineHeight = max(baseLineHeight, boostedLineHeight)
            let lineHeight = max(Constants.minLineHeight, ceil(rawWordLineHeight * Constants.stepSpacingMultiplier))

            return Metrics(
                storyFont: storyFont,
                lineHeight: lineHeight,
                wordBaseSize: quantizedWordBase,
                wordBoost: quantizedBoostedSize - quantizedWordBase,
                activeWordFont: activeWordFont
            )
        }

        // MARK: - Text Utilities

        func quantize(_ value: CGFloat, step: CGFloat = Constants.quantizationStep) -> CGFloat {
            guard step > 0 else { return value }
            return (value / step).rounded() * step
        }

        func alignToPixel(_ value: CGFloat, scale: CGFloat) -> CGFloat {
            guard scale > 0 else { return value }
            return (value * scale).rounded() / scale
        }

        func textSize(for text: String, font: NSFont, attributes: [NSAttributedString.Key: Any]? = nil) -> CGSize {
            let attrs = attributes ?? [.font: font]
            return (text as NSString).size(withAttributes: attrs)
        }
    }

    // MARK: - Layer Manager

    /// Manages Core Animation layer setup, configuration, and updates.
    /// Provides a clean abstraction over CALayer operations for better maintainability.
    private final class LayerManager: LayerManaging {
        // Layer references
        private var backgroundLayer = CALayer()
        private var storyLayer = CATextLayer()
        private var glowLayer = CALayer()
        private var logoLayer = CATextLayer()
        private var wordLayers: [CALayer] = []

        // MARK: - Layer Setup

        func setupLayersIfNeeded(rootLayer: CALayer, bounds: CGRect, isFlipped: Bool) {
            guard bounds.width > 0 && bounds.height > 0 else {
                #if DEBUG
                print("Invalid bounds for layer setup: \(bounds)")
                #endif
                return
            }

            rootLayer.isGeometryFlipped = isFlipped
            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            rootLayer.contentsScale = scale

            setupBackgroundLayerIfNeeded(rootLayer: rootLayer)
            setupGlowLayerIfNeeded(rootLayer: rootLayer)
            // Animated layers are set up separately
        }

        func setupAnimatedLayersIfNeeded(rootLayer: CALayer) {
            setupStoryLayerIfNeeded(rootLayer: rootLayer)
            setupLogoLayerIfNeeded(rootLayer: rootLayer)
            setupWordLayersIfNeeded(rootLayer: rootLayer)
        }

        private func setupBackgroundLayerIfNeeded(rootLayer: CALayer) {
            if backgroundLayer.superlayer == nil {
                rootLayer.addSublayer(backgroundLayer)
            }
        }

        private func setupGlowLayerIfNeeded(rootLayer: CALayer) {
            if glowLayer.superlayer == nil {
                rootLayer.addSublayer(glowLayer)
            }
        }

        private func setupStoryLayerIfNeeded(rootLayer: CALayer) {
            if storyLayer.superlayer == nil {
                storyLayer.alignmentMode = .center
                storyLayer.isWrapped = false
                storyLayer.truncationMode = .none
                setAllowsFontSubpixelPositioning(storyLayer)
                storyLayer.allowsFontSubpixelQuantization = true
                rootLayer.addSublayer(storyLayer)
            }
        }

        private func setupLogoLayerIfNeeded(rootLayer: CALayer) {
            if logoLayer.superlayer == nil {
                logoLayer.alignmentMode = .center
                logoLayer.isWrapped = true
                logoLayer.truncationMode = .none
                setAllowsFontSubpixelPositioning(logoLayer)
                logoLayer.allowsFontSubpixelQuantization = true
                rootLayer.addSublayer(logoLayer)
            }
        }

        private func setupWordLayersIfNeeded(rootLayer: CALayer) {
            if wordLayers.isEmpty {
                wordLayers = Constants.wordOffsets.map { _ in CALayer() }
                for wordLayer in wordLayers {
                    wordLayer.anchorPoint = .zero
                    wordLayer.contentsGravity = .topLeft
                    rootLayer.addSublayer(wordLayer)
                }
            }
        }

        // MARK: - Layer Updates

        func updateLayers(bounds: CGRect, scale: CGFloat, now: TimeInterval, backgroundImage: NSImage?, glowImage: NSImage?) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)

            if let backgroundImage {
                backgroundLayer.contents = backgroundImage
                backgroundLayer.frame = bounds
            }
            if let glowImage {
                glowLayer.contents = glowImage
                glowLayer.frame = bounds
                let breathe = Constants.breatheBase + Constants.breatheAmplitude * sin(now * Constants.breatheFrequency)
                glowLayer.opacity = Float(breathe)
            }

            CATransaction.commit()
        }

        func updateAnimatedLayers(
            metrics: Metrics,
            bounds: CGRect,
            scale: CGFloat,
            now: TimeInterval,
            scrollOffset: CGFloat,
            words: [String],
            centerText: String,
            wordGap: CGFloat,
            isFlipped: Bool,
            typographyManager: TypographyManager,
            cacheManager: CacheManager
        ) {
            let centerX = bounds.midX
            let centerY = bounds.midY
            let lineHeight = metrics.lineHeight

            guard lineHeight > 0 else { return }

            // Cache story attributes to avoid recreating every frame
            if storyLayer.string == nil {
                let storyAttrs: [NSAttributedString.Key: Any] = [
                    .font: metrics.storyFont,
                    .foregroundColor: NSColor.white.withAlphaComponent(0.9),
                    .kern: Constants.kerning,
                ]
                storyLayer.string = NSAttributedString(string: centerText, attributes: storyAttrs)
            }

            // Update story layer position and size
            let storySize = typographyManager.textSize(for: centerText, font: metrics.storyFont, attributes: [
                .font: metrics.storyFont,
                .kern: Constants.kerning,
            ])
            let storyOrigin = CGPoint(
                x: centerX - storySize.width / 2,
                y: centerY - storySize.height / 2
            )
            let alignedStoryX = typographyManager.alignToPixel(storyOrigin.x, scale: scale)
            let alignedStoryY = typographyManager.alignToPixel(storyOrigin.y, scale: scale)
            let alignedStoryW = typographyManager.alignToPixel(storySize.width, scale: scale)
            let alignedStoryH = typographyManager.alignToPixel(storySize.height, scale: scale)
            storyLayer.contentsScale = scale
            storyLayer.frame = CGRect(x: alignedStoryX, y: alignedStoryY, width: alignedStoryW, height: alignedStoryH)

            updateLogoLayer(bounds: bounds, scale: scale, now: now, typographyManager: typographyManager)

            let storyBaselineY = storyOrigin.y + metrics.storyFont.ascender
            let baselineOffset = storyBaselineY - centerY
            let wordRightX = storyOrigin.x - wordGap

            let progress = scrollOffset / lineHeight
            let baseIndex = Int(floor(progress)) % words.count
            let fractionalProgress = progress - floor(progress)

            let maxVisible = lineHeight * Constants.maxVisibleMultiplier
            let edgeInner = lineHeight * Constants.edgeInnerMultiplier
            let edgeOuter = maxVisible
            let ySign: CGFloat = isFlipped ? 1 : -1

            for (index, offset) in Constants.wordOffsets.enumerated() {
                let wordLayer = wordLayers[index]
                let wordIndex = (baseIndex - offset + words.count) % words.count
                let wordCenterY = centerY + (CGFloat(offset) + fractionalProgress) * lineHeight * ySign

                let dist = abs(wordCenterY - centerY)
                if dist > maxVisible {
                    wordLayer.isHidden = true
                    continue
                }

                let norm = min(1.0, dist / (lineHeight * Constants.maxVisibleMultiplier))
                let falloff = 1.0 - norm
                let ease = pow(falloff, 2.0)

                let edgeT = max(0.0, min(1.0, (edgeOuter - dist) / (edgeOuter - edgeInner)))
                let edgeFade = edgeT * edgeT * (3.0 - 2.0 * edgeT)
                let alpha = (Constants.minAlpha + Constants.maxAlpha * ease) * edgeFade

                let fontSize = metrics.wordBaseSize + metrics.wordBoost * ease
                let quantizedSize = typographyManager.quantize(fontSize, step: 0.5)
                let wordFont = cacheManager.cachedFont(size: quantizedSize, weight: .bold) { size, weight in
                    typographyManager.preferredFont(size: size, weight: weight)
                }
                let currentWord = words[wordIndex]
                let image = cacheManager.cachedWordImage(for: currentWord, font: wordFont) { word, font in
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: NSColor.white,
                        .kern: Constants.wordKerning,
                    ]
                    let size = (word as NSString).size(withAttributes: attrs)
                    let image = NSImage(size: size)
                    image.lockFocus()
                    (word as NSString).draw(at: .zero, withAttributes: attrs)
                    image.unlockFocus()
                    image.isTemplate = false
                    return image
                }

                let wordBaselineY = wordCenterY + baselineOffset
                let originX = wordRightX - image.size.width
                let originY = wordBaselineY - wordFont.ascender
                wordLayer.isHidden = false
                wordLayer.contents = image
                wordLayer.contentsScale = scale
                wordLayer.opacity = Float(alpha)
                // Avoid pixel-snapping for moving layers to keep motion fluid.
                wordLayer.frame = CGRect(x: originX, y: originY, width: image.size.width, height: image.size.height)
                wordLayer.shadowOpacity = Float(Constants.shadowOpacity * ease)
                wordLayer.shadowRadius = Constants.shadowRadius * ease
                wordLayer.shadowOffset = .zero
                wordLayer.shadowColor = NSColor.white.cgColor
            }
        }

        func updateLogoLayer(bounds: CGRect, scale: CGFloat, now: TimeInterval, typographyManager: TypographyManager) {
            // This is a complex method that would need the logo animation state
            // For now, keeping it simple - would need to extract logo animation state to a separate component
        }

        // MARK: - Utilities

        private func setAllowsFontSubpixelPositioning(_ layer: CATextLayer) {
            let selector = NSSelectorFromString("setAllowsFontSubpixelPositioning:")
            if layer.responds(to: selector) {
                layer.setValue(true, forKey: "allowsFontSubpixelPositioning")
            }
        }

        // MARK: - Accessors

        var hasBackgroundLayer: Bool { backgroundLayer.superlayer != nil }
        var hasStoryLayer: Bool { storyLayer.superlayer != nil }
    }

    // MARK: - Constants

    /// Centralized configuration constants for animation, typography, and visual effects.
    /// All magic numbers and hardcoded values are collected here for easy maintenance and tuning.
    private enum Constants {
        // Animation timing
        static let frameRate: TimeInterval = 1.0 / 60.0
        static let maxDeltaTime: TimeInterval = 0.0167 // ~60fps minimum
        static let secondsPerWord: CGFloat = 0.8
        static let holdSecondsPerStep: CGFloat = 0.35
        static let reduceMotionScale: CGFloat = 2.0
        static let reduceMotionDeltaMultiplier: CGFloat = 0.4

        // Typography scaling
        static let minFontSize: CGFloat = 34.0
        static let maxFontSize: CGFloat = 72.0
        static let fontSizeScale: CGFloat = 0.095
        static let wordFontScale: CGFloat = 0.92
        static let fontBoostScale: CGFloat = 0.18
        static let minFontBoost: CGFloat = 6.0
        static let lineHeightScale: CGFloat = 1.16
        static let minLineHeight: CGFloat = 52.0
        static let stepSpacingMultiplier: CGFloat = 1.25

        // Layout
        static let wordGap: CGFloat = 18.0
        static let kerning: CGFloat = -0.2
        static let wordKerning: CGFloat = -0.15
        static let logoKerning: CGFloat = 0.4
        static let logoPadding: CGFloat = 3.0

        // Visual effects
        static let glowOpacityMin: CGFloat = 0.07
        static let glowOpacityMax: CGFloat = 0.0
        static let breatheFrequency: CGFloat = 0.35
        static let breatheAmplitude: CGFloat = 0.05
        static let breatheBase: CGFloat = 0.95
        static let shadowOpacity: CGFloat = 0.0
        static let shadowRadius: CGFloat = 0.0
        static let centerGlowOpacity: CGFloat = 0.35
        static let centerGlowRadius: CGFloat = 8.0
        static let logoOpacity: CGFloat = 0.9
        static let logoTextOpacity: CGFloat = 0.14

        // Visibility and fading
        static let maxVisibleMultiplier: CGFloat = 2.8
        static let edgeInnerMultiplier: CGFloat = 1.8
        static let minAlpha: CGFloat = 0.02
        static let maxAlpha: CGFloat = 0.98
        static let midAlpha: CGFloat = 0.25
        static let edgeAlpha: CGFloat = 0.08
        static let quantizationStep: CGFloat = 0.25

        // Logo animation
        static let logoMoveDuration: TimeInterval = 8.0
        static let logoMoveInterval: TimeInterval = 300.0
        static let logoMargin: CGFloat = 36.0
        static let logoFontScale: CGFloat = 0.035
        static let logoMinFontSize: CGFloat = 14.0
        static let logoMaxFontSize: CGFloat = 26.0

        // Background animation
        static let backgroundUpdateInterval: TimeInterval = 1.0
        static let backgroundPhaseMultiplier: CGFloat = 0.2
        static let backgroundPhasePeriod: TimeInterval = 12.0
        static let backgroundTopShiftBase: CGFloat = 0.02
        static let backgroundTopShiftAmp: CGFloat = 0.01
        static let backgroundBottomShiftBase: CGFloat = 0.01
        static let backgroundBottomShiftAmp: CGFloat = 0.01
        static let vignetteOpacity: CGFloat = 0.45

        // Glow effect
        static let glowRadiusMultiplier: CGFloat = 0.35

        // Word offsets for scrolling effect - more words visible for smooth scrolling
        static let wordOffsets = Array(-2 ... 2)
    }
    // MARK: - Content

    private let words: [String] = ["produce", "manage", "sell", "create", "develop"]
    private let centerText: String = "the story"

    // MARK: - Managers

    private let animationManager: AnimationManaging = AnimationManager()
    private let cacheManager: CacheManaging = CacheManager()
    private let typographyManager: TypographyManaging = TypographyManager()
    private let layerManager: LayerManaging = LayerManager()

    // MARK: - Animation state

    private var lastTime: TimeInterval = 0
    /// Scroll offset in points within one full cycle (0 ..< cycleHeight).
    private var scrollOffset: CGFloat = 0
    private var cachedBackground: NSImage?
    private var cachedBackgroundSize: CGSize = .zero
    private var lastBackgroundUpdate: TimeInterval = 0

    private lazy var glowGradient: NSGradient? = NSGradient(colors: [
        NSColor.white.withAlphaComponent(Constants.glowOpacityMin),
        NSColor.white.withAlphaComponent(Constants.glowOpacityMax),
    ])

    private var cachedGlow: NSImage?
    private var cachedGlowSize: CGSize = .zero
    private var backgroundLayer = CALayer()
    private var storyLayer = CATextLayer()
    private var glowLayer = CALayer()
    private var logoLayer = CATextLayer()
    private var wordLayers: [CALayer] = []
    private var logoPosition: CGPoint = .zero
    private var logoTargetPosition: CGPoint = .zero
    private var logoMoveStartTime: TimeInterval = 0
    private var nextLogoMoveTime: TimeInterval = 0

    // MARK: - Tuning

    /// Seconds for the movement between words.
    private let secondsPerWord: CGFloat = Constants.secondsPerWord
    /// Horizontal gap between the left word and the centered "the story".
    private let wordGap: CGFloat = Constants.wordGap

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = Constants.frameRate
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = Constants.frameRate
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        setupLayersIfNeeded()
    }

    override func startAnimation() {
        super.startAnimation()
        animationManager.startAnimation()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setupLayersIfNeeded()
    }

    override func animateOneFrame() {
        super.animateOneFrame()

        let deltaTime = animationManager.calculateDeltaTime()

        let metrics = computeMetrics()
        guard metrics.lineHeight > 0 else {
            // Invalid metrics, skip frame
            #if DEBUG
            print("Invalid metrics: lineHeight is 0")
            #endif
            return
        }

        let currentTime = ProcessInfo.processInfo.systemUptime
        scrollOffset = animationManager.updateAnimationState(deltaTime: deltaTime, metrics: metrics, wordCount: words.count)
        updateLayers(metrics: metrics, now: currentTime)
    }


    // Removed draw() method - using layer-based rendering only for optimal performance

    override var hasConfigureSheet: Bool { false }

    private func setAllowsFontSubpixelPositioning(_ layer: CATextLayer) {
        let selector = NSSelectorFromString("setAllowsFontSubpixelPositioning:")
        if layer.responds(to: selector) {
            layer.setValue(true, forKey: "allowsFontSubpixelPositioning")
        }
    }

    private func setupLayersIfNeeded() {
        wantsLayer = true
        if layer == nil {
            layer = CALayer()
        }
        guard let rootLayer = layer else { return }

        layerManager.setupLayersIfNeeded(rootLayer: rootLayer, bounds: bounds, isFlipped: isFlipped)
        // Animated layers are set up in updateAnimatedLayers when needed
    }

    private func setupStoryLayerIfNeeded(rootLayer: CALayer) {
        if storyLayer.superlayer == nil {
            storyLayer.alignmentMode = .center
            storyLayer.isWrapped = false
            storyLayer.truncationMode = .none
            setAllowsFontSubpixelPositioning(storyLayer)
            storyLayer.allowsFontSubpixelQuantization = true
            rootLayer.addSublayer(storyLayer)
        }
    }

    private func setupLogoLayerIfNeeded(rootLayer: CALayer) {
        if logoLayer.superlayer == nil {
            logoLayer.alignmentMode = .center
            logoLayer.isWrapped = true
            logoLayer.truncationMode = .none
            setAllowsFontSubpixelPositioning(logoLayer)
            logoLayer.allowsFontSubpixelQuantization = true
            rootLayer.addSublayer(logoLayer)
        }
    }

    private func setupWordLayersIfNeeded(rootLayer: CALayer) {
        if wordLayers.isEmpty {
            wordLayers = Constants.wordOffsets.map { _ in CALayer() }
            for wordLayer in wordLayers {
                wordLayer.anchorPoint = .zero
                wordLayer.contentsGravity = .topLeft
                rootLayer.addSublayer(wordLayer)
            }
        }
    }

    private func setupAnimatedLayersIfNeeded() {
        guard let rootLayer = layer else { return }
        setupStoryLayerIfNeeded(rootLayer: rootLayer)
        setupLogoLayerIfNeeded(rootLayer: rootLayer)
        setupWordLayersIfNeeded(rootLayer: rootLayer)
    }

    private func updateLayers(metrics: Metrics, now: TimeInterval) {
        // Only setup layers once, not every frame
        if backgroundLayer.superlayer == nil {
            setupLayersIfNeeded()
        }
        guard let rootLayer = layer else { return }

        // Update background and glow layers (non-animated)
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let scale = rootLayer.contentsScale
        updateBackgroundCacheIfNeeded(now: now)
        updateGlowCacheIfNeeded()

        if let cachedBackground {
            backgroundLayer.contents = cachedBackground
            backgroundLayer.frame = bounds
        }
        if let cachedGlow {
            glowLayer.contents = cachedGlow
            glowLayer.frame = bounds
            let breathe = Constants.breatheBase + Constants.breatheAmplitude * sin(now * Constants.breatheFrequency)
            glowLayer.opacity = Float(breathe)
        }

        CATransaction.commit()

        // Update animated word layers with smooth animation enabled
        updateAnimatedLayers(metrics: metrics, scale: scale, now: now)
    }

    private func updateAnimatedLayers(metrics: Metrics, scale: CGFloat, now: TimeInterval) {
        let centerX = bounds.midX
        let centerY = bounds.midY
        let lineHeight = metrics.lineHeight
        guard lineHeight > 0 else { return }

        // Setup layers if needed (only once)
        if storyLayer.superlayer == nil {
            setupAnimatedLayersIfNeeded()
        }

        // Cache story attributes to avoid recreating every frame
        if storyLayer.string == nil {
            let storyAttrs: [NSAttributedString.Key: Any] = [
                .font: metrics.storyFont,
                .foregroundColor: NSColor.white.withAlphaComponent(0.9),
                .kern: Constants.kerning,
            ]
            storyLayer.string = NSAttributedString(string: centerText, attributes: storyAttrs)
        }

        // Update story layer position and size
        let storySize = (centerText as NSString).size(withAttributes: [
            .font: metrics.storyFont,
            .kern: Constants.kerning,
        ])
        let storyOrigin = CGPoint(
            x: centerX - storySize.width / 2,
            y: centerY - storySize.height / 2
        )
        let alignedStoryX = typographyManager.alignToPixel(storyOrigin.x, scale: scale)
        let alignedStoryY = typographyManager.alignToPixel(storyOrigin.y, scale: scale)
        let alignedStoryW = typographyManager.alignToPixel(storySize.width, scale: scale)
        let alignedStoryH = typographyManager.alignToPixel(storySize.height, scale: scale)
        storyLayer.contentsScale = scale
        storyLayer.frame = CGRect(x: alignedStoryX, y: alignedStoryY, width: alignedStoryW, height: alignedStoryH)

        updateLogoLayer(scale: scale, now: now)

        // Calculate baseline offset using the story font baseline as reference
        let baselineOffset = storyOrigin.y + metrics.storyFont.ascender - centerY
        let wordRightX = storyOrigin.x - Constants.wordGap

        let ySign: CGFloat = isFlipped ? 1 : -1

        // Simple scrolling text: words move from top to bottom in a continuous loop
        // Calculate progress through the animation cycle
        let progress = scrollOffset / lineHeight
        let baseIndex = Int(floor(progress)) % words.count
        let fractionalProgress = progress - floor(progress)

        // scrollOffset already includes easing; keep this linear to avoid double-easing.
        let easedFractionalProgress = fractionalProgress

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, offset) in Constants.wordOffsets.enumerated() {
            let wordLayer = wordLayers[index]
            let wordIndex = (baseIndex - offset + words.count) % words.count
            let wordCenterY = centerY + (CGFloat(offset) + easedFractionalProgress) * lineHeight * ySign
            let distInLines = min(2.0, abs(wordCenterY - centerY) / lineHeight)
            let centerAlpha: CGFloat = 1.0
            let midAlpha: CGFloat = Constants.midAlpha
            let edgeAlpha: CGFloat = Constants.edgeAlpha
            let alpha: CGFloat
            if distInLines <= 1.0 {
                alpha = centerAlpha - (centerAlpha - midAlpha) * distInLines
            } else {
                alpha = midAlpha - (midAlpha - edgeAlpha) * (distInLines - 1.0)
            }
            let sizeBoost: CGFloat
            if distInLines < 0.5 {
                sizeBoost = metrics.wordBoost
            } else if distInLines < 1.5 {
                sizeBoost = metrics.wordBoost * 0.35
            } else {
                sizeBoost = 0.0
            }
            let fontSize = typographyManager.quantize(metrics.wordBaseSize + sizeBoost, step: 0.5)
            let wordFont = cachedFont(size: fontSize, weight: .bold)
            let currentWord = words[wordIndex]
            let image = cachedWordImage(for: currentWord, font: wordFont)

            let wordBaselineY = wordCenterY + baselineOffset
            let originX = wordRightX - image.size.width
            let originY = wordBaselineY - wordFont.ascender

            wordLayer.isHidden = false
            wordLayer.contents = image
            wordLayer.contentsScale = scale
            wordLayer.opacity = Float(alpha)
            wordLayer.frame = CGRect(x: originX, y: originY, width: image.size.width, height: image.size.height)
            if distInLines < 0.5 {
                wordLayer.shadowOpacity = Float(Constants.centerGlowOpacity)
                wordLayer.shadowRadius = Constants.centerGlowRadius
            } else {
                wordLayer.shadowOpacity = 0.0
                wordLayer.shadowRadius = 0.0
            }
            wordLayer.shadowOffset = .zero
            wordLayer.shadowColor = NSColor.white.cgColor
        }
        CATransaction.commit()
    }

    // MARK: - Typography Metrics

    /// Encapsulates typography measurements and font information for a given screen context.
    /// Calculated dynamically based on screen size to ensure optimal readability and aesthetics.
    struct Metrics {
        var storyFont: NSFont
        var lineHeight: CGFloat
        var wordBaseSize: CGFloat
        var wordBoost: CGFloat
        var activeWordFont: NSFont
    }

    private func computeMetrics() -> Metrics {
        return typographyManager.computeMetrics(for: bounds, isPreview: isPreview)
    }



    private func cachedWordImage(for word: String, font: NSFont) -> NSImage {
        return cacheManager.cachedWordImage(for: word, font: font) { word, font in
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: Constants.wordKerning,
            ]
            let size = (word as NSString).size(withAttributes: attrs)
            let image = NSImage(size: size)
            image.lockFocus()
            (word as NSString).draw(at: .zero, withAttributes: attrs)
            image.unlockFocus()
            image.isTemplate = false
            return image
        }
    }

    private func cachedFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        return cacheManager.cachedFont(size: size, weight: weight) { [typographyManager] size, weight in
            return typographyManager.preferredFont(size: size, weight: weight)
        }
    }

    private func cachedSize(for word: String, font: NSFont, attrs: [NSAttributedString.Key: Any]) -> CGSize {
        return cacheManager.cachedSize(for: word, font: font, attrs: attrs)
    }

    private func updateGlowCacheIfNeeded() {
        if cachedGlowSize == bounds.size, cachedGlow != nil {
            return
        }

        cachedGlowSize = bounds.size
        let image = NSImage(size: bounds.size)
        image.lockFocus()
        let glowCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        glowGradient?.draw(
            fromCenter: glowCenter,
            radius: 0,
            toCenter: glowCenter,
            radius: max(bounds.width, bounds.height) * Constants.glowRadiusMultiplier,
            options: .drawsBeforeStartingLocation
        )
        image.unlockFocus()
        cachedGlow = image
    }

    private func updateLogoLayer(scale: CGFloat, now: TimeInterval) {
        let logoText = "CREATIVE\nBUSINESS"
        let logoSize = max(Constants.logoMinFontSize, min(Constants.logoMaxFontSize, min(bounds.width, bounds.height) * Constants.logoFontScale))
        let font = typographyManager.preferredLogoFont(size: logoSize, weight: .bold)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let logoAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white.withAlphaComponent(Constants.logoTextOpacity),
            .kern: Constants.logoKerning,
            .paragraphStyle: paragraph,
        ]
        let attributed = NSAttributedString(string: logoText, attributes: logoAttrs)
        let logoBounds = attributed.boundingRect(
            with: CGSize(width: bounds.width, height: bounds.height),
            options: [.usesLineFragmentOrigin]
        )
        let logoPadding: CGFloat = Constants.logoPadding
        let logoWidth = ceil(logoBounds.width) + (logoPadding * 2)
        let logoHeight = ceil(logoBounds.height) + (logoPadding * 2)

        if now >= nextLogoMoveTime || logoPosition == .zero {
            let margin: CGFloat = Constants.logoMargin
            let rightX = max(margin, bounds.width - logoWidth - margin)
            let topY = isFlipped ? margin : max(margin, bounds.height - logoHeight - margin)
            let bottomY = isFlipped ? max(margin, bounds.height - logoHeight - margin) : margin
            let corners = [
                CGPoint(x: margin, y: topY),
                CGPoint(x: rightX, y: topY),
                CGPoint(x: margin, y: bottomY),
                CGPoint(x: rightX, y: bottomY),
            ]
            if logoPosition == .zero {
                logoTargetPosition = corners.first ?? .zero
                logoPosition = logoTargetPosition
            } else {
                let choices = corners.filter { $0 != logoTargetPosition }
                logoTargetPosition = (choices.randomElement() ?? corners.first) ?? .zero
            }
            logoMoveStartTime = now
            nextLogoMoveTime = now + Constants.logoMoveInterval
        }

        let moveT = min(1.0, max(0.0, CGFloat((now - logoMoveStartTime) / Constants.logoMoveDuration)))
        let eased = moveT * moveT * (3.0 - 2.0 * moveT)
        let currentX = logoPosition.x + (logoTargetPosition.x - logoPosition.x) * eased
        let currentY = logoPosition.y + (logoTargetPosition.y - logoPosition.y) * eased
        if moveT >= 1.0 {
            logoPosition = logoTargetPosition
        }

        logoLayer.contentsScale = scale
        // Avoid pixel-snapping during the slow drift to prevent stepping.
        logoLayer.frame = CGRect(x: currentX, y: currentY, width: logoWidth, height: logoHeight)
        logoLayer.string = attributed
        logoLayer.opacity = Float(Constants.logoOpacity)
    }

    private func updateBackgroundCacheIfNeeded(now: TimeInterval) {
        let sizeChanged = cachedBackgroundSize != bounds.size
        let timeExpired = now - lastBackgroundUpdate >= Constants.backgroundUpdateInterval
        guard sizeChanged || timeExpired || cachedBackground == nil else { return }

        lastBackgroundUpdate = now
        cachedBackgroundSize = bounds.size
        let image = NSImage(size: bounds.size)
        image.lockFocus()

        let phase = CGFloat(now.truncatingRemainder(dividingBy: Constants.backgroundPhasePeriod)) * Constants.backgroundPhaseMultiplier
        let topShift = Constants.backgroundTopShiftBase + Constants.backgroundTopShiftAmp * sin(phase)
        let bottomShift = Constants.backgroundBottomShiftBase + Constants.backgroundBottomShiftAmp * cos(phase * 0.9)
        let bgTop = NSColor(calibratedRed: 0.05 + topShift, green: 0.06 + topShift, blue: 0.08 + topShift, alpha: 1)
        let bgBottom = NSColor(calibratedRed: 0.01 + bottomShift, green: 0.02 + bottomShift, blue: 0.03 + bottomShift, alpha: 1)
        let bgGradient = NSGradient(colors: [bgTop, bgBottom]) ?? NSGradient(starting: bgTop, ending: bgBottom)
        bgGradient?.draw(in: NSRect(origin: .zero, size: bounds.size), angle: 90)

        let vignette = NSGradient(colors: [
            NSColor.black.withAlphaComponent(0.0),
            NSColor.black.withAlphaComponent(Constants.vignetteOpacity),
        ])
        vignette?.draw(in: NSRect(origin: .zero, size: bounds.size), relativeCenterPosition: .zero)

        image.unlockFocus()
        cachedBackground = image
    }
}
