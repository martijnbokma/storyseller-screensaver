import AppKit

/// Calculates and caches typography and layout metrics based on view bounds
final class MetricsCalculator {
    // MARK: - Properties

    private var cachedMetrics: (bounds: NSRect, metrics: Metrics)?

    // MARK: - Metrics Calculation

    /// Computes metrics for the given bounds
    /// - Parameters:
    ///   - bounds: The view bounds
    ///   - isPreview: Whether this is preview mode
    ///   - fontProvider: Function to get preferred font
    /// - Returns: Computed metrics
    func computeMetrics(
        for bounds: NSRect,
        isPreview: Bool,
        fontProvider: (CGFloat, NSFont.Weight) -> NSFont
    ) -> Metrics {
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

        let storyFont = fontProvider(storySize, .regular)
        let activeWordFont = fontProvider(wordBase + boost, .semibold)

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

    /// Invalidates the metrics cache
    func invalidateCache() {
        cachedMetrics = nil
    }
}
