import SwiftUI

struct OnboardingContinueButton: View {
    var label: String = "Next"
    var isEnabled: Bool = true
    let action: () -> Void

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
                            .fill(isEnabled ? Color.bfOnboardingButtonChip : Color.bfBorder.opacity(0.8))
                    )
                    .foregroundStyle(isEnabled ? Color.white : Color.bfTextDisabled)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(Typography.ctaButton)
            .foregroundStyle(isEnabled ? Color.bfOnboardingButtonText : Color.bfTextDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(Color.bfOnboardingButtonFill) : AnyShapeStyle(Color.white.opacity(0.2)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(isEnabled ? Color.bfOnboardingButtonBorder : Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .shadow(color: isEnabled ? Color.black.opacity(0.12) : Color.clear, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
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
