import AppKit
import QuartzCore
import ScreenSaver

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
    private var cachedBackground: NSImage?
    private var cachedBackgroundSize: CGSize = .zero
    private var lastBackgroundUpdate: TimeInterval = 0
    private let backgroundUpdateInterval: TimeInterval = 1.0
    private lazy var glowGradient: NSGradient? = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.07),
        NSColor.white.withAlphaComponent(0.0),
    ])

    private var fontCache: [String: NSFont] = [:]
    private var sizeCache: [String: CGSize] = [:]
    private var wordImageCache: [String: NSImage] = [:]
    private var cachedGlow: NSImage?
    private var cachedGlowSize: CGSize = .zero

    private let wordOffsets = Array(-3 ... 3)
    private var backgroundLayer = CALayer()
    private var storyLayer = CATextLayer()
    private var glowLayer = CALayer()
    private var logoLayer = CATextLayer()
    private var wordLayers: [CALayer] = []
    private var logoPosition: CGPoint = .zero
    private var logoTargetPosition: CGPoint = .zero
    private var logoMoveStartTime: TimeInterval = 0
    private let logoMoveDuration: TimeInterval = 8
    private var nextLogoMoveTime: TimeInterval = 0
    private let logoMoveInterval: TimeInterval = 300

    // MARK: - Tuning

    /// Seconds for the movement between words.
    private let secondsPerWord: CGFloat = 0.95
    /// Seconds each word stays centered before moving on.
    private let holdSecondsPerWord: CGFloat = 0.25
    /// Horizontal gap between the left word and the centered "the story".
    private let wordGap: CGFloat = 18

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 60.0
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 60.0
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        setupLayersIfNeeded()
    }

    override func startAnimation() {
        super.startAnimation()
        lastTime = ProcessInfo.processInfo.systemUptime
        elapsedTime = 0
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setupLayersIfNeeded()
    }

    override func animateOneFrame() {
        super.animateOneFrame()

        let currentTime = ProcessInfo.processInfo.systemUptime
        let deltaTime = CGFloat(min(max(currentTime - lastTime, 0.0), 0.05))
        lastTime = currentTime

        let metrics = computeMetrics()
        guard metrics.lineHeight > 0 else {
            setNeedsDisplay(bounds)
            return
        }

        updateAnimationState(deltaTime: deltaTime, metrics: metrics)
        updateLayers(metrics: metrics, now: currentTime)
    }

    private func updateAnimationState(deltaTime: CGFloat, metrics: Metrics) {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let motionScale: CGFloat = reduceMotion ? 2.0 : 1.0
        let moveSeconds = max(0.05, secondsPerWord * motionScale)
        let holdSeconds = max(0.0, holdSecondsPerWord * motionScale)
        let wordDuration = moveSeconds + holdSeconds
        let cycleDuration = wordDuration * CGFloat(words.count)

        let scaledDeltaTime = reduceMotion ? deltaTime * 0.4 : deltaTime
        elapsedTime = (elapsedTime + scaledDeltaTime).truncatingRemainder(dividingBy: cycleDuration)

        let wordIndex = Int(floor(elapsedTime / wordDuration)) % words.count
        let localTime = elapsedTime - CGFloat(wordIndex) * wordDuration

        let transitionProgress: CGFloat
        if localTime <= holdSeconds {
            transitionProgress = 0.0
        } else {
            transitionProgress = min(1.0, (localTime - holdSeconds) / moveSeconds)
        }

        scrollOffset = (CGFloat(wordIndex) + transitionProgress) * metrics.lineHeight
    }

    override func draw(_: NSRect) {
        guard layer == nil else { return }
        guard NSGraphicsContext.current != nil else { return }

        let metrics = computeMetrics()

        updateBackgroundCacheIfNeeded(now: ProcessInfo.processInfo.systemUptime)
        if let cachedBackground {
            cachedBackground.draw(in: bounds)
        }

        let centerX = bounds.midX
        let centerY = bounds.midY

        // Attributes for the fixed center text (SF Pro Display look)
        let storyAttrs: [NSAttributedString.Key: Any] = [
            .font: metrics.storyFont,
            .foregroundColor: NSColor.white.withAlphaComponent(0.9),
            .kern: -0.2,
        ]

        let storySize = (centerText as NSString).size(withAttributes: storyAttrs)

        // Word carousel geometry
        let lineHeight = metrics.lineHeight
        guard lineHeight > 0 else { return }

        // Progress within the word cycle.
        let progress = scrollOffset / lineHeight
        let baseIndex = Int(floor(progress)) % words.count
        let fractionalProgress = progress - floor(progress)

        // Soft glow behind the phrase
        let storyOrigin = CGPoint(
            x: centerX - storySize.width / 2,
            y: centerY - storySize.height / 2
        )
        let storyBaselineY = storyOrigin.y + metrics.storyFont.ascender
        let baselineOffset = storyBaselineY - centerY
        let glowCenter = CGPoint(x: centerX, y: centerY)
        glowGradient?.draw(fromCenter: glowCenter, radius: 0, toCenter: glowCenter, radius: max(bounds.width, bounds.height) * 0.35, options: [])

        // Draw "the story" with phrase-centric positioning
        (centerText as NSString).draw(at: storyOrigin, withAttributes: storyAttrs)

        // Words are right-aligned to sit nicely before "the story".
        let wordRightX = storyOrigin.x - wordGap

        // Positioning rule:
        // - Only 5 words are visible (2 above, 1 center, 2 below).
        // - As scrollOffset increases by lineHeight, the next word becomes centered.
        let ySign: CGFloat = isFlipped ? 1 : -1
        for offset in -3 ... 3 {
            // Offsets are visual positions; index mapping keeps list order while moving downward.
            let wordIndex = (baseIndex - offset + words.count) % words.count
            // Negative offsets sit above the center line; move linearly downward.
            let wordCenterY = centerY + (CGFloat(offset) + fractionalProgress) * lineHeight * ySign

            // Visual treatment: fade + slight size emphasis near center
            let dist = abs(wordCenterY - centerY)
            // Hard cull to avoid a third row peeking in below/above.
            // Extended so incoming words become visible earlier for a smoother loop.
            let maxVisible = lineHeight * 2.8
            if dist > maxVisible {
                continue
            }
            let norm = min(1.0, dist / (lineHeight * 2.8))
            let falloff = 1.0 - norm
            let ease = pow(falloff, 2.0)

            // Fade-in/out at the edges so the first word appears smoothly.
            let edgeInner = lineHeight * 1.8
            let edgeOuter = maxVisible
            let edgeT = max(0.0, min(1.0, (edgeOuter - dist) / (edgeOuter - edgeInner)))
            let edgeFade = edgeT * edgeT * (3.0 - 2.0 * edgeT)

            // Keep center strong; outer rows are nearly ghosted.
            let alpha = (0.02 + 0.98 * ease) * edgeFade
            let fontSize = metrics.wordBaseSize + metrics.wordBoost * ease
            let wordFont = cachedFont(size: fontSize, weight: .bold)

            let shadow = NSShadow()
            shadow.shadowOffset = .zero
            shadow.shadowBlurRadius = 16 * ease
            shadow.shadowColor = NSColor.white.withAlphaComponent(0.65 * ease)

            let wordAttrs: [NSAttributedString.Key: Any] = [
                .font: wordFont,
                .foregroundColor: NSColor.white.withAlphaComponent(alpha),
                .shadow: shadow,
                .kern: -0.15,
            ]

            let currentWord = words[wordIndex]
            let wordSize = cachedSize(for: currentWord, font: wordFont, attrs: wordAttrs)

            // Align vertically with "the story" baseline using font metrics.
            // Align the word baseline to the story baseline, preserving row position.
            let wordBaselineY = wordCenterY + baselineOffset
            let wordOrigin = CGPoint(
                x: wordRightX - wordSize.width,
                y: wordBaselineY - wordFont.ascender
            )

            (currentWord as NSString).draw(at: wordOrigin, withAttributes: wordAttrs)
        }

        // Optional subtle center guide (disabled by default).
        // ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.05).cgColor)
        // ctx.setLineWidth(1)
        // ctx.stroke(CGRect(x: 0, y: centerY, width: bounds.width, height: 1))
    }

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

        configureRootLayer(rootLayer: rootLayer)
        setupBackgroundLayerIfNeeded(rootLayer: rootLayer)
        setupGlowLayerIfNeeded(rootLayer: rootLayer)
        setupStoryLayerIfNeeded(rootLayer: rootLayer)
        setupLogoLayerIfNeeded(rootLayer: rootLayer)
        setupWordLayersIfNeeded(rootLayer: rootLayer)
    }

    private func configureRootLayer(rootLayer: CALayer) {
        rootLayer.isGeometryFlipped = isFlipped
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        rootLayer.contentsScale = scale
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
            wordLayers = wordOffsets.map { _ in CALayer() }
            for wordLayer in wordLayers {
                wordLayer.anchorPoint = .zero
                wordLayer.contentsGravity = .topLeft
                rootLayer.addSublayer(wordLayer)
            }
        }
    }

    private func updateLayers(metrics: Metrics, now: TimeInterval) {
        setupLayersIfNeeded()
        guard let rootLayer = layer else { return }

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
            let breathe = 0.95 + 0.05 * sin(now * 0.35)
            glowLayer.opacity = Float(breathe)
        }

        let centerX = bounds.midX
        let centerY = bounds.midY
        let lineHeight = metrics.lineHeight
        guard lineHeight > 0 else { return }

        let storyAttrs: [NSAttributedString.Key: Any] = [
            .font: metrics.storyFont,
            .foregroundColor: NSColor.white.withAlphaComponent(0.9),
            .kern: -0.2,
        ]
        let storySize = (centerText as NSString).size(withAttributes: storyAttrs)
        let storyOrigin = CGPoint(
            x: centerX - storySize.width / 2,
            y: centerY - storySize.height / 2
        )
        let alignedStoryX = alignToPixel(storyOrigin.x, scale: scale)
        let alignedStoryY = alignToPixel(storyOrigin.y, scale: scale)
        let alignedStoryW = alignToPixel(storySize.width, scale: scale)
        let alignedStoryH = alignToPixel(storySize.height, scale: scale)
        storyLayer.contentsScale = scale
        storyLayer.frame = CGRect(x: alignedStoryX, y: alignedStoryY, width: alignedStoryW, height: alignedStoryH)
        storyLayer.string = NSAttributedString(string: centerText, attributes: storyAttrs)

        updateLogoLayer(scale: scale, now: now)

        let storyBaselineY = storyOrigin.y + metrics.storyFont.ascender
        let baselineOffset = storyBaselineY - centerY
        let wordRightX = storyOrigin.x - wordGap

        let progress = scrollOffset / lineHeight
        let baseIndex = Int(floor(progress)) % words.count
        let fractionalProgress = progress - floor(progress)

        let maxVisible = lineHeight * 2.8
        let edgeInner = lineHeight * 1.8
        let edgeOuter = maxVisible
        let ySign: CGFloat = isFlipped ? 1 : -1

        for (index, offset) in wordOffsets.enumerated() {
            let wordLayer = wordLayers[index]
            let wordIndex = (baseIndex - offset + words.count) % words.count
            let wordCenterY = centerY + (CGFloat(offset) + fractionalProgress) * lineHeight * ySign

            let dist = abs(wordCenterY - centerY)
            if dist > maxVisible {
                wordLayer.isHidden = true
                continue
            }

            let norm = min(1.0, dist / (lineHeight * 2.8))
            let falloff = 1.0 - norm
            let ease = pow(falloff, 2.0)

            let edgeT = max(0.0, min(1.0, (edgeOuter - dist) / (edgeOuter - edgeInner)))
            let edgeFade = edgeT * edgeT * (3.0 - 2.0 * edgeT)
            let alpha = (0.02 + 0.98 * ease) * edgeFade

            let fontSize = metrics.wordBaseSize + metrics.wordBoost * ease
            let quantizedSize = quantize(fontSize, step: 0.25)
            let wordFont = cachedFont(size: quantizedSize, weight: .bold)
            let currentWord = words[wordIndex]
            let image = cachedWordImage(for: currentWord, font: wordFont)

            let wordBaselineY = wordCenterY + baselineOffset
            let originX = wordRightX - image.size.width
            let originY = wordBaselineY - wordFont.ascender
            wordLayer.isHidden = false
            wordLayer.contents = image
            wordLayer.contentsScale = scale
            wordLayer.opacity = Float(alpha)
            // Avoid pixel-snapping for moving layers to keep motion fluid.
            wordLayer.frame = CGRect(x: originX, y: originY, width: image.size.width, height: image.size.height)
            wordLayer.shadowOpacity = Float(0.25 * ease)
            wordLayer.shadowRadius = 6.0 * ease
            wordLayer.shadowOffset = .zero
            wordLayer.shadowColor = NSColor.white.cgColor
        }

        CATransaction.commit()
    }

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

        let storyFont = preferredFont(size: storySize, weight: .regular)
        let activeWordFont = preferredFont(size: wordBase + boost, weight: .semibold)

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

    private func quantize(_ value: CGFloat, step: CGFloat) -> CGFloat {
        guard step > 0 else { return value }
        return (value / step).rounded() * step
    }

    private func alignToPixel(_ value: CGFloat, scale: CGFloat) -> CGFloat {
        guard scale > 0 else { return value }
        return (value * scale).rounded() / scale
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

    private func preferredLogoFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
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

    private func cachedWordImage(for word: String, font: NSFont) -> NSImage {
        let key = "\(word)|\(font.fontName)|\(font.pointSize)"
        if let cached = wordImageCache[key] {
            return cached
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
            .kern: -0.15,
        ]
        let size = (word as NSString).size(withAttributes: attrs)
        let image = NSImage(size: size)
        image.lockFocus()
        (word as NSString).draw(at: .zero, withAttributes: attrs)
        image.unlockFocus()
        image.isTemplate = false

        wordImageCache[key] = image
        return image
    }

    private func cachedFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        let key = "\(size)|\(weight.rawValue)"
        if let cached = fontCache[key] {
            return cached
        }
        let font = preferredFont(size: size, weight: weight)
        fontCache[key] = font
        return font
    }

    private func cachedSize(for word: String, font: NSFont, attrs: [NSAttributedString.Key: Any]) -> CGSize {
        let key = "\(word)|\(font.fontName)|\(font.pointSize)"
        if let cached = sizeCache[key] {
            return cached
        }
        let size = (word as NSString).size(withAttributes: attrs)
        sizeCache[key] = size
        return size
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
            radius: max(bounds.width, bounds.height) * 0.35,
            options: []
        )
        image.unlockFocus()
        cachedGlow = image
    }

    private func updateLogoLayer(scale: CGFloat, now: TimeInterval) {
        let logoText = "CREATIVE\nBUSINESS"
        let logoSize = max(14, min(26, min(bounds.width, bounds.height) * 0.035))
        let font = preferredLogoFont(size: logoSize, weight: .bold)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let logoAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white.withAlphaComponent(0.14),
            .kern: 0.4,
            .paragraphStyle: paragraph,
        ]
        let attributed = NSAttributedString(string: logoText, attributes: logoAttrs)
        let logoBounds = attributed.boundingRect(
            with: CGSize(width: bounds.width, height: bounds.height),
            options: [.usesLineFragmentOrigin]
        )
        let logoPadding: CGFloat = 3
        let logoWidth = ceil(logoBounds.width) + (logoPadding * 2)
        let logoHeight = ceil(logoBounds.height) + (logoPadding * 2)

        if now >= nextLogoMoveTime || logoPosition == .zero {
            let margin: CGFloat = 36
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
            nextLogoMoveTime = now + logoMoveInterval
        }

        let moveT = min(1.0, max(0.0, CGFloat((now - logoMoveStartTime) / logoMoveDuration)))
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
        logoLayer.opacity = 0.9
    }

    private func updateBackgroundCacheIfNeeded(now: TimeInterval) {
        let sizeChanged = cachedBackgroundSize != bounds.size
        let timeExpired = now - lastBackgroundUpdate >= backgroundUpdateInterval
        guard sizeChanged || timeExpired || cachedBackground == nil else { return }

        lastBackgroundUpdate = now
        cachedBackgroundSize = bounds.size
        let image = NSImage(size: bounds.size)
        image.lockFocus()

        let phase = CGFloat(now.truncatingRemainder(dividingBy: 12.0)) * 0.2
        let topShift = 0.02 + 0.01 * sin(phase)
        let bottomShift = 0.01 + 0.01 * cos(phase * 0.9)
        let bgTop = NSColor(calibratedRed: 0.05 + topShift, green: 0.06 + topShift, blue: 0.08 + topShift, alpha: 1)
        let bgBottom = NSColor(calibratedRed: 0.01 + bottomShift, green: 0.02 + bottomShift, blue: 0.03 + bottomShift, alpha: 1)
        let bgGradient = NSGradient(colors: [bgTop, bgBottom]) ?? NSGradient(starting: bgTop, ending: bgBottom)
        bgGradient?.draw(in: NSRect(origin: .zero, size: bounds.size), angle: 90)

        let vignette = NSGradient(colors: [
            NSColor.black.withAlphaComponent(0.0),
            NSColor.black.withAlphaComponent(0.45),
        ])
        vignette?.draw(in: NSRect(origin: .zero, size: bounds.size), relativeCenterPosition: .zero)

        image.unlockFocus()
        cachedBackground = image
    }
}
