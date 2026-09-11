import SwiftUI

// MARK: - Design System

enum AppTheme {
    // MARK: Brand
    static let brandPrimary   = Color(hex: "0066CC")
    static let brandSecondary = Color(hex: "FFD700")

    // MARK: Backgrounds
    static let background       = Color(hex: "0D0D0D")
    static let surface          = Color(hex: "1A1A2E")
    static let surfaceSecondary = Color(hex: "16213E")
    static let surfaceElevated  = Color(hex: "252543")

    // MARK: Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(hex: "8E9BAE")
    static let textTertiary  = Color(hex: "636376")

    // MARK: Status
    static let success = Color(hex: "34C759")
    static let warning = Color(hex: "FF9500")
    static let error   = Color(hex: "FF3B30")
    static let neutral = Color(hex: "636366")
    static let info    = Color(hex: "0A84FF")

    // MARK: Corner Radius
    static let radiusSmall:  CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge:  CGFloat = 20
    static let radiusXL:     CGFloat = 28

    // MARK: Gradients
    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [brandPrimary.opacity(0.9), surface],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var darkGradient: LinearGradient {
        LinearGradient(
            colors: [surface, background],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [brandPrimary, brandPrimary.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var statusGradient: LinearGradient {
        LinearGradient(
            colors: [brandSecondary.opacity(0.8), brandPrimary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
