import Foundation
import AppKit

/// Enhanced accessibility support for the screensaver.
struct AccessibilityManager {
    /// Whether to reduce motion for accessibility.
    static var shouldReduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    /// Whether to increase contrast for accessibility.
    static var prefersHighContrast: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }

    /// Adjust animation speed based on accessibility preferences.
    /// - Parameter baseSpeed: Base animation speed
    /// - Returns: Adjusted speed (0 if reduced motion, otherwise baseSpeed)
    static func adjustedAnimationSpeed(baseSpeed: CGFloat) -> CGFloat {
        shouldReduceMotion ? 0 : baseSpeed
    }

    /// Adjust alpha component for high contrast mode.
    /// - Parameter baseAlpha: Base alpha value
    /// - Returns: Adjusted alpha (higher if high contrast, otherwise baseAlpha)
    static func adjustedAlpha(baseAlpha: CGFloat) -> CGFloat {
        prefersHighContrast ? min(1.0, baseAlpha * 1.2) : baseAlpha
    }

    /// Adjust font weight for high contrast mode.
    /// - Parameter baseWeight: Base font weight
    /// - Returns: Adjusted weight (heavier if high contrast, otherwise baseWeight)
    static func adjustedFontWeight(baseWeight: NSFont.Weight) -> NSFont.Weight {
        if prefersHighContrast {
            switch baseWeight {
            case .regular, .medium:
                return .semibold
            case .light, .thin, .ultraLight:
                return .regular
            default:
                return baseWeight
            }
        }
        return baseWeight
    }
}
