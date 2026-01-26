import AppKit

/// Manages accessibility features for the screensaver
struct AccessibilityManager {
    /// Whether to reduce motion for accessibility
    static var shouldReduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    /// Whether high contrast mode is enabled
    static var prefersHighContrast: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }

    /// Adjusts animation speed based on accessibility preferences
    /// - Parameter baseSpeed: The base animation speed
    /// - Returns: Adjusted speed (0 if motion should be reduced)
    static func adjustedAnimationSpeed(baseSpeed: CGFloat) -> CGFloat {
        shouldReduceMotion ? 0 : baseSpeed
    }

    /// Adjusts opacity for high contrast mode
    /// - Parameter baseOpacity: The base opacity value
    /// - Returns: Adjusted opacity (higher for high contrast)
    static func adjustedOpacity(baseOpacity: CGFloat) -> CGFloat {
        prefersHighContrast ? min(1.0, baseOpacity * 1.3) : baseOpacity
    }
}
