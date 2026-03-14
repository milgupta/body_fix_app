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

    // MARK: - Solid Colors

    static let bfNavy = Color(hex: "0A1628")
    static let bfCardDark = Color(hex: "1C1C1E")
    static let bfCardDarker = Color(hex: "2A2A2E")
    static let bfElectricBlue = Color(hex: "2D7FF9")
    static let bfTeal = Color(hex: "00C9A7")
    static let bfMint = Color(hex: "7BEDA0")
    static let bfTextPrimary = Color.white
    static let bfTextSecondary = Color(hex: "8899AA")
    static let bfSliderWarm = Color(hex: "FF6B35")
}

// MARK: - ShapeStyle Convenience

extension ShapeStyle where Self == Color {
    static var bfTextPrimary: Color { .bfTextPrimary }
    static var bfTextSecondary: Color { .bfTextSecondary }
    static var bfNavy: Color { .bfNavy }
    static var bfCardDark: Color { .bfCardDark }
    static var bfCardDarker: Color { .bfCardDarker }
    static var bfElectricBlue: Color { .bfElectricBlue }
    static var bfTeal: Color { .bfTeal }
    static var bfMint: Color { .bfMint }
    static var bfSliderWarm: Color { .bfSliderWarm }
}

// MARK: - Gradient Presets

extension ShapeStyle where Self == LinearGradient {
    static var bfSelectionGradient: LinearGradient { LinearGradient.bfSelectionGradient }
    static var bfProgressGradient: LinearGradient { LinearGradient.bfProgressGradient }
    static var bfSplashGradient: LinearGradient { LinearGradient.bfSplashGradient }
}

extension LinearGradient {
    static let bfSelectionGradient = LinearGradient(
        colors: [.bfTeal, .bfMint],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let bfProgressGradient = LinearGradient(
        colors: [.bfTeal, Color(hex: "4ADE80")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let bfSplashGradient = LinearGradient(
        colors: [.bfTeal, Color(hex: "6DD5A0"), .bfMint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
