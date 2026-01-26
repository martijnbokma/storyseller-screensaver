import Foundation

/// Custom error types for the screensaver.
enum ScreensaverError: LocalizedError {
    case invalidMetrics(String)
    case invalidGraphicsContext
    case invalidBounds
    case fontLoadFailure(String)
    case invalidAnimationState(String)

    var errorDescription: String? {
        switch self {
        case .invalidMetrics(let message):
            return "Invalid metrics: \(message)"
        case .invalidGraphicsContext:
            return "No graphics context available for drawing"
        case .invalidBounds:
            return "Invalid view bounds"
        case .fontLoadFailure(let fontName):
            return "Failed to load font: \(fontName)"
        case .invalidAnimationState(let message):
            return "Invalid animation state: \(message)"
        }
    }

    var failureReason: String? {
        switch self {
        case .invalidMetrics:
            return "Metrics calculation resulted in invalid values (e.g., zero or negative line height)"
        case .invalidGraphicsContext:
            return "NSGraphicsContext.current is nil"
        case .invalidBounds:
            return "View bounds are invalid (zero or negative dimensions)"
        case .fontLoadFailure:
            return "Font file not found or corrupted"
        case .invalidAnimationState:
            return "Animation state contains invalid values"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidMetrics:
            return "Check view bounds and ensure they are valid before computing metrics"
        case .invalidGraphicsContext:
            return "Ensure draw(_:) is called within a valid graphics context"
        case .invalidBounds:
            return "Verify view has been properly laid out before drawing"
        case .fontLoadFailure:
            return "Verify font files are included in the bundle and properly registered"
        case .invalidAnimationState:
            return "Reset animation state or check timing calculations"
        }
    }
}
