import Foundation
import AppKit

/// Typography and layout metrics for the screensaver.
struct Metrics {
    var storyFont: NSFont
    var lineHeight: CGFloat
    var wordBaseSize: CGFloat
    var wordBoost: CGFloat
    var activeWordFont: NSFont
}

/// Calculates and caches typography and layout metrics based on view bounds.
struct MetricsCalculator {
    // MARK: - Properties

    /// Cached metrics with associated bounds.
    private var cachedMetrics: (bounds: NSRect, metrics: Metrics)?

    /// Font provider function for loading fonts.
    private let fontProvider: (CGFloat, NSFont.Weight) -> NSFont

    // MARK: - Initialization

    /// Initialize the metrics calculator.
    /// - Parameter fontProvider: Function to load fonts by size and weight
    init(fontProvider: @escaping (CGFloat, NSFont.Weight) -> NSFont) {
        self.fontProvider = fontProvider
    }

    // MARK: - Metrics Calculation

    /// Compute metrics for the given bounds.
    /// - Parameters:
    ///   - bounds: View bounds
    ///   - isPreview: Whether this is preview mode
    /// - Returns: Calculated metrics
    func computeMetrics(for bounds: NSRect, isPreview: Bool) -> Metrics {
        // Cache metrics to avoid recalculation when bounds haven't changed
        if let cached = cachedMetrics, cached.bounds == bounds {
            return cached.metrics
        }

        // Scale typography to screen size but keep it tasteful in preview mode.
        let minDim = max(ScreensaverConfiguration.minScreenDimension, min(bounds.width, bounds.height))

        // Base size tuned for typical screens; clamped so it doesn't explode.
        let base = max(
            ScreensaverConfiguration.minFontSize,
            min(ScreensaverConfiguration.minFontSizeMax, minDim * ScreensaverConfiguration.baseFontSizeScale)
        )
        let storySize = base
        let wordBase = base * ScreensaverConfiguration.wordFontSizeRatio

        // Slight emphasis at the center word.
        let boost = max(ScreensaverConfiguration.minWordBoost, storySize * ScreensaverConfiguration.wordBoostRatio)

        let storyFont = fontProvider(storySize, .regular)
        let activeWordFont = fontProvider(wordBase + boost, .semibold)

        // Line height: enough separation to feel like a carousel, not a list.
        let lineHeight = max(ScreensaverConfiguration.minLineHeight, storySize * ScreensaverConfiguration.lineHeightMultiplier)

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

    /// Invalidate the metrics cache.
    func invalidateCache() {
        cachedMetrics = nil
    }
}
