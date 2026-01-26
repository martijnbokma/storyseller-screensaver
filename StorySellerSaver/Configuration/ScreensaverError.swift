import Foundation

/// Errors that can occur during screensaver operation
enum ScreensaverError: LocalizedError {
    case invalidMetrics(String)
    case invalidGraphicsContext
    case invalidBounds
    case fontLoadFailure(String)

    var errorDescription: String? {
        switch self {
        case .invalidMetrics(let message):
            return "Invalid metrics: \(message)"
        case .invalidGraphicsContext:
            return "No graphics context available"
        case .invalidBounds:
            return "Invalid view bounds"
        case .fontLoadFailure(let fontName):
            return "Failed to load font: \(fontName)"
        }
    }
}
