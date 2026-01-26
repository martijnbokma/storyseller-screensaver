import Foundation
import AppKit

/// Manages fonts, colors, shadows, and visual effects.
final class StyleManager {
    // MARK: - Properties

    /// Cached word attributes keyed by font size and alpha.
    private var cachedWordAttrs: [String: [NSAttributedString.Key: Any]] = [:]

    /// Cached story attributes.
    private var cachedStoryAttrs: [NSAttributedString.Key: Any]?

    /// Cached logo attributes.
    private var cachedLogoAttrs: [NSAttributedString.Key: Any]?

    /// Font provider function.
    private let fontProvider: (CGFloat, NSFont.Weight) -> NSFont

    // MARK: - Initialization

    /// Initialize the style manager.
    /// - Parameter fontProvider: Function to load fonts by size and weight
    init(fontProvider: @escaping (CGFloat, NSFont.Weight) -> NSFont) {
        self.fontProvider = fontProvider
    }

    // MARK: - Attribute Creation

    /// Get word attributes for the given parameters.
    /// - Parameters:
    ///   - fontSize: Font size in points
    ///   - alpha: Alpha component (0.0 to 1.0)
    ///   - ease: Easing factor for shadow intensity
    /// - Returns: Dictionary of text attributes
    func wordAttributes(fontSize: CGFloat, alpha: CGFloat, ease: CGFloat) -> [NSAttributedString.Key: Any] {
        // Use integer-based cache key to avoid floating-point precision issues
        let fontSizeKey = Int(fontSize * 100)
        let alphaKey = Int(alpha * 1000)
        let cacheKey = "\(fontSizeKey)-\(alphaKey)"

        if let cached = cachedWordAttrs[cacheKey] {
            return cached
        }

        let wordFont = fontProvider(fontSize, .bold)
        let shadow = NSShadow()
        shadow.shadowOffset = .zero
        shadow.shadowBlurRadius = ScreensaverConfiguration.shadowBlurRadiusMultiplier * ease
        shadow.shadowColor = NSColor.white.withAlphaComponent(ScreensaverConfiguration.shadowColorAlphaMultiplier * ease)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: wordFont,
            .foregroundColor: NSColor.white.withAlphaComponent(alpha),
            .shadow: shadow,
            .kern: ScreensaverConfiguration.wordTextKern
        ]

        cachedWordAttrs[cacheKey] = attrs
        return attrs
    }

    /// Get story attributes for the given metrics.
    /// - Parameter metrics: Layout metrics
    /// - Returns: Dictionary of text attributes
    func storyAttributes(metrics: Metrics) -> [NSAttributedString.Key: Any] {
        if let cached = cachedStoryAttrs {
            return cached
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: metrics.storyFont,
            .foregroundColor: NSColor.white.withAlphaComponent(ScreensaverConfiguration.storyTextAlpha),
            .kern: ScreensaverConfiguration.storyTextKern
        ]

        cachedStoryAttrs = attrs
        return attrs
    }

    /// Get logo attributes for the given font size.
    /// Note: Logo size depends on bounds, so this is called per-render.
    /// - Parameter fontSize: Font size for the logo
    /// - Returns: Dictionary of text attributes
    func logoAttributes(fontSize: CGFloat) -> [NSAttributedString.Key: Any] {
        let logoFont = fontProvider(fontSize, .bold)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: logoFont,
            .foregroundColor: NSColor.white.withAlphaComponent(ScreensaverConfiguration.logoTextAlpha),
            .kern: ScreensaverConfiguration.logoTextKern
        ]

        return attrs
    }

    // MARK: - Cache Management

    /// Clean up caches to prevent memory bloat.
    func cleanupCache() {
        cachedWordAttrs.removeAll(keepingCapacity: true)
        cachedLogoAttrs = nil
        // Note: storyAttrs kept as it's less likely to change
    }

    /// Invalidate logo cache (e.g., when bounds change).
    func invalidateLogoCache() {
        cachedLogoAttrs = nil
    }
}
