import Foundation
import AppKit

extension NSFont {
    /// Load preferred font with fallback chain.
    /// Tries Cera Pro first, then Poppins, Avenir, Helvetica, and finally system font.
    /// - Parameters:
    ///   - size: Font size in points
    ///   - weight: Font weight
    /// - Returns: Loaded font (never nil, falls back to system font)
    static func preferredFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        // Ensure size is valid
        let safeSize = max(1, size)

        // Try Cera Pro first (primary font)
        // Map NSFont.Weight to Cera Pro variants
        // Try multiple naming conventions as font names can vary
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
}
