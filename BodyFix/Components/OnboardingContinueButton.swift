import SwiftUI

struct OnboardingContinueButton: View {
    enum Style {
        case standard
        case gradientPrimary
    }

    var label: String = "Next"
    var style: Style = .standard
    var isEnabled: Bool = true
    let action: () -> Void

    private var usesGradient: Bool { style == .gradientPrimary }

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action()
        } label: {
            ZStack {
                Text(label)
                    .frame(maxWidth: .infinity, alignment: .center)

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(arrowBackground)
                    )
                    .foregroundStyle(arrowForeground)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(Typography.ctaButton)
            .foregroundStyle(labelForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(buttonBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(buttonBorder, lineWidth: 1)
                    )
            )
            .shadow(color: isEnabled ? Color.black.opacity(usesGradient ? 0.18 : 0.12) : Color.clear, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var labelForeground: Color {
        guard isEnabled else { return .bfTextDisabled }
        return usesGradient ? .white : .bfOnboardingButtonText
    }

    private var arrowForeground: Color {
        guard isEnabled else { return .bfTextDisabled }
        return usesGradient ? Color.bfMint : .white
    }

    private var arrowBackground: Color {
        guard isEnabled else { return .bfBorder.opacity(0.8) }
        return usesGradient ? Color.white.opacity(0.92) : .bfOnboardingButtonChip
    }

    private var buttonBackground: AnyShapeStyle {
        if isEnabled, usesGradient {
            AnyShapeStyle(LinearGradient.bfGradient)
        } else if isEnabled {
            AnyShapeStyle(Color.bfOnboardingButtonFill)
        } else {
            AnyShapeStyle(Color.white.opacity(0.2))
        }
    }

    private var buttonBorder: Color {
        guard isEnabled else { return .white.opacity(0.12) }
        return usesGradient ? Color.white.opacity(0.22) : .bfOnboardingButtonBorder
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        VStack(spacing: 16) {
            OnboardingContinueButton(label: "Next", isEnabled: true) {}
            OnboardingContinueButton(label: "Start Body Scan", isEnabled: true) {}
            OnboardingContinueButton(label: "Next", isEnabled: false) {}
        }
        .padding()
    }
}
