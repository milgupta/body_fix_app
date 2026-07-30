import SwiftUI

enum OnboardingSeverityLayout {
    static let headerHeight: CGFloat = 190
    static let controlsTopSpacing: CGFloat = 32
    static let lowerCaptionHeight: CGFloat = 17
}

struct OnboardingSeverityBadge: View {
    let text: String
    let value: Int
    let range: ClosedRange<Int>
    let accessibilityText: String

    private var normalizedValue: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return Double(value - range.lowerBound) / Double(range.upperBound - range.lowerBound)
    }

    private var accentColor: Color {
        switch normalizedValue {
        case ..<0.34:
            Color(hex: "#3F9A7D")
        case ..<0.68:
            Color(hex: "#D79532")
        default:
            Color(hex: "#D65F55")
        }
    }

    var body: some View {
        Text(text)
            .font(Typography.sliderValue)
            .foregroundStyle(accentColor)
            .contentTransition(.numericText(value: Double(value)))
            .padding(.horizontal, 26)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(accentColor.opacity(0.11))
                    .overlay {
                        Capsule()
                            .stroke(accentColor.opacity(0.24), lineWidth: 1)
                    }
                    .shadow(color: accentColor.opacity(0.16), radius: 18, y: 8)
            }
            .animation(.easeInOut(duration: 0.24), value: value)
            .accessibilityLabel(accessibilityText)
    }
}
