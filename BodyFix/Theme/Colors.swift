import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static let bfBackground = Color(hex: "#0F172A")
    static let bfCard = Color(hex: "#1E293B")
    static let bfBorder = Color(hex: "#334155")
    static let bfMint = Color(hex: "#5EEAD4")
    static let bfTeal = Color(hex: "#14B8A6")
    static let bfSliderWarm = Color(hex: "#F59E0B")
    static let bfBlue = Color(hex: "#3B82F6")
    static let bfTextPrimary = Color(hex: "#F8FAFC")
    static let bfTextSecondary = Color(hex: "#E2E8F0")
    static let bfTextTertiary = Color(hex: "#94A3B8")
    static let bfTextMuted = Color(hex: "#64748B")
    static let bfTextDisabled = Color(hex: "#475569")

    // Legacy aliases (onboarding + existing components)
    static let bfNavy = bfBackground
    static let bfCardDark = bfCard
    static let bfCardDarker = bfBorder
    static let bfElectricBlue = bfBlue
}

extension ShapeStyle where Self == Color {
    static var bfBackground: Color { .bfBackground }
    static var bfCard: Color { .bfCard }
    static var bfBorder: Color { .bfBorder }
    static var bfMint: Color { .bfMint }
    static var bfTeal: Color { .bfTeal }
    static var bfSliderWarm: Color { .bfSliderWarm }
    static var bfBlue: Color { .bfBlue }
    static var bfTextPrimary: Color { .bfTextPrimary }
    static var bfTextSecondary: Color { .bfTextSecondary }
    static var bfTextTertiary: Color { .bfTextTertiary }
    static var bfTextMuted: Color { .bfTextMuted }
    static var bfTextDisabled: Color { .bfTextDisabled }
    static var bfNavy: Color { .bfNavy }
    static var bfCardDark: Color { .bfCardDark }
    static var bfCardDarker: Color { .bfCardDarker }
    static var bfElectricBlue: Color { .bfElectricBlue }
}

extension LinearGradient {
    static let bfGradient = LinearGradient(
        colors: [Color(hex: "#3B82F6"), Color(hex: "#5EEAD4")],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Legacy names map to the primary accent gradient.
    static let bfSelectionGradient = bfGradient
    static let bfProgressGradient = bfGradient
    static let bfSplashGradient = bfGradient
}

extension ShapeStyle where Self == LinearGradient {
    static var bfGradient: LinearGradient { .bfGradient }
    static var bfSelectionGradient: LinearGradient { .bfSelectionGradient }
    static var bfProgressGradient: LinearGradient { .bfProgressGradient }
    static var bfSplashGradient: LinearGradient { .bfSplashGradient }
}
