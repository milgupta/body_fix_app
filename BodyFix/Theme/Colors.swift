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

    static let bfBackground = Color(hex: "#FFFFFF")
    static let bfCard = Color(hex: "#F6F8FB")
    static let bfBorder = Color(hex: "#D9E1EC")
    static let bfMint = Color(hex: "#163B73")
    static let bfTeal = Color(hex: "#2B5C96")
    static let bfSliderGreen = Color(hex: "#58BFA2")
    static let bfSliderWarm = Color(hex: "#E6A23C")
    static let bfBlue = Color(hex: "#4F7DBA")
    static let bfTextPrimary = Color(hex: "#1A2433")
    static let bfTextSecondary = Color(hex: "#425466")
    static let bfTextTertiary = Color(hex: "#6B7A8C")
    static let bfTextMuted = Color(hex: "#8291A3")
    static let bfTextDisabled = Color(hex: "#A5B1BF")
    static let bfPageBackground = Color(hex: "#FCFBF8")
    static let bfSurfaceMuted = Color(hex: "#F8F4EE")
    static let bfSurfaceElevated = Color(hex: "#FFFDF9")
    static let bfOnboardingButtonFill = Color(hex: "#F7F3EC")
    static let bfOnboardingButtonBorder = Color.white.opacity(0.28)
    static let bfOnboardingButtonText = Color(hex: "#16233B")
    static let bfOnboardingButtonChip = Color(hex: "#86A7D9")
    static let bfGlassFill = Color.white.opacity(0.58)
    static let bfGlassHighlight = Color.white.opacity(0.72)
    static let bfGlassBorder = Color.white.opacity(0.65)
    static let bfTabBarFill = Color(hex: "#1B2330").opacity(0.88)
    static let bfTabBarBorder = Color.white.opacity(0.16)
    static let bfTabBarSpotlight = Color.white.opacity(0.14)
    static let bfTabBarSpotlightCore = Color.white.opacity(0.24)
    static let bfHeroSurface = Color(hex: "#0E172A")
    static let bfHeroSurfaceSecondary = Color(hex: "#16233B")
    static let bfHeroGhostCircle = Color(hex: "#22314C")
    static let bfAccent = Color(hex: "#4F7DBA")
    static let bfAccentWarm = Color(hex: "#E8B06A")
    static let bfHeroTextPrimary = Color(hex: "#F8FAFC")
    static let bfHeroTextSecondary = Color(hex: "#B6C2D7")

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
    static var bfSliderGreen: Color { .bfSliderGreen }
    static var bfSliderWarm: Color { .bfSliderWarm }
    static var bfBlue: Color { .bfBlue }
    static var bfTextPrimary: Color { .bfTextPrimary }
    static var bfTextSecondary: Color { .bfTextSecondary }
    static var bfTextTertiary: Color { .bfTextTertiary }
    static var bfTextMuted: Color { .bfTextMuted }
    static var bfTextDisabled: Color { .bfTextDisabled }
    static var bfPageBackground: Color { .bfPageBackground }
    static var bfSurfaceMuted: Color { .bfSurfaceMuted }
    static var bfSurfaceElevated: Color { .bfSurfaceElevated }
    static var bfOnboardingButtonFill: Color { .bfOnboardingButtonFill }
    static var bfOnboardingButtonBorder: Color { .bfOnboardingButtonBorder }
    static var bfOnboardingButtonText: Color { .bfOnboardingButtonText }
    static var bfOnboardingButtonChip: Color { .bfOnboardingButtonChip }
    static var bfGlassFill: Color { .bfGlassFill }
    static var bfGlassHighlight: Color { .bfGlassHighlight }
    static var bfGlassBorder: Color { .bfGlassBorder }
    static var bfTabBarFill: Color { .bfTabBarFill }
    static var bfTabBarBorder: Color { .bfTabBarBorder }
    static var bfTabBarSpotlight: Color { .bfTabBarSpotlight }
    static var bfTabBarSpotlightCore: Color { .bfTabBarSpotlightCore }
    static var bfHeroSurface: Color { .bfHeroSurface }
    static var bfHeroSurfaceSecondary: Color { .bfHeroSurfaceSecondary }
    static var bfHeroGhostCircle: Color { .bfHeroGhostCircle }
    static var bfAccent: Color { .bfAccent }
    static var bfAccentWarm: Color { .bfAccentWarm }
    static var bfHeroTextPrimary: Color { .bfHeroTextPrimary }
    static var bfHeroTextSecondary: Color { .bfHeroTextSecondary }
    static var bfNavy: Color { .bfNavy }
    static var bfCardDark: Color { .bfCardDark }
    static var bfCardDarker: Color { .bfCardDarker }
    static var bfElectricBlue: Color { .bfElectricBlue }
}

extension LinearGradient {
    static let bfGradient = LinearGradient(
        colors: [Color.bfMint, Color.bfAccent],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let bfHeroGradient = LinearGradient(
        colors: [Color.bfHeroSurface, Color.bfHeroSurfaceSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Legacy names map to the primary accent gradient.
    static let bfSelectionGradient = bfGradient
    static let bfProgressGradient = bfGradient
    static let bfSplashGradient = bfGradient
}

extension ShapeStyle where Self == LinearGradient {
    static var bfGradient: LinearGradient { .bfGradient }
    static var bfHeroGradient: LinearGradient { .bfHeroGradient }
    static var bfSelectionGradient: LinearGradient { .bfSelectionGradient }
    static var bfProgressGradient: LinearGradient { .bfProgressGradient }
    static var bfSplashGradient: LinearGradient { .bfSplashGradient }
}
