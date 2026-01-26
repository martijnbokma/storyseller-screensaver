import AppKit
import os.log

/// Manages fonts, colors, shadows, and visual effects
final class StyleManager {
    // MARK: - Properties

    private var cachedWordAttrsCache: [String: [NSAttributedString.Key: Any]] = [:]
    private var cachedStoryAttrs: [NSAttributedString.Key: Any]?
    private var cachedLogoAttrs: [NSAttributedString.Key: Any]?

    private static let logger = OSLog(
        subsystem: "com.creativebusiness.storysellersaver",
        category: "StyleManager"
    )

    // MARK: - Word Attributes

    /// Creates word attributes with caching
    /// - Parameters:
    ///   - fontSize: Font size for the word
    ///   - alpha: Opacity for the word
    ///   - ease: Easing factor (0.0 to 1.0)
    ///   - fontProvider: Function to get preferred font
    /// - Returns: Attributes dictionary
    func wordAttributes(
        fontSize: CGFloat,
        alpha: CGFloat,
        ease: CGFloat,
        fontProvider: (CGFloat, NSFont.Weight) -> NSFont
    ) -> [NSAttributedString.Key: Any] {
        // Use integer-based cache key to avoid floating-point precision issues
        let fontSizeKey = Int(fontSize * 100)
        let alphaKey = Int(alpha * 1000)
        let cacheKey = "\(fontSizeKey)-\(alphaKey)"

        if let cached = cachedWordAttrsCache[cacheKey] {
            return cached
        }

        let wordFont = fontProvider(fontSize, .bold)
        let shadow = NSShadow()
        shadow.shadowOffset = .zero
        shadow.shadowBlurRadius = 16 * ease
        shadow.shadowColor = NSColor.white.withAlphaComponent(0.65 * ease)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: wordFont,
            .foregroundColor: NSColor.white.withAlphaComponent(alpha),
            .shadow: shadow,
            .kern: -0.15
        ]

        cachedWordAttrsCache[cacheKey] = attrs
        return attrs
    }

    // MARK: - Story Attributes

    /// Creates story text attributes with caching
    /// - Parameters:
    ///   - metrics: Current metrics
    ///   - fontProvider: Function to get preferred font
    /// - Returns: Attributes dictionary
    func storyAttributes(
        metrics: Metrics,
        fontProvider: (CGFloat, NSFont.Weight) -> NSFont
    ) -> [NSAttributedString.Key: Any] {
        if let cached = cachedStoryAttrs {
            return cached
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: metrics.storyFont,
            .foregroundColor: NSColor.white.withAlphaComponent(0.9),
            .kern: -0.2
        ]

        cachedStoryAttrs = attrs
        return attrs
    }

    // MARK: - Logo Attributes

    /// Creates logo attributes with caching
    /// - Parameters:
    ///   - fontSize: Font size for the logo
    ///   - fontProvider: Function to get preferred font
    /// - Returns: Attributes dictionary
    func logoAttributes(
        fontSize: CGFloat,
        fontProvider: (CGFloat, NSFont.Weight) -> NSFont
    ) -> [NSAttributedString.Key: Any] {
        if let cached = cachedLogoAttrs {
            return cached
        }

        let logoFont = fontProvider(fontSize, .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: logoFont,
            .foregroundColor: NSColor.white.withAlphaComponent(0.3),
            .kern: 1.2
        ]

        cachedLogoAttrs = attrs
        return attrs
    }

    // MARK: - Font Loading

    /// Gets the preferred font with fallback chain
    /// - Parameters:
    ///   - size: Font size
    ///   - weight: Font weight
    /// - Returns: Loaded font
    func preferredFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        // Ensure size is valid
        let safeSize = max(1, size)

        // Try Cera Pro first (primary font)
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

    // MARK: - Cache Management

    /// Cleans up caches to prevent memory bloat
    func cleanupCache() {
        cachedWordAttrsCache.removeAll(keepingCapacity: true)
        cachedLogoAttrs = nil
        // Note: storyAttrs kept as it's small and frequently used
    }
}
