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
            HStack(spacing: 10) {
                Text(label)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.18)))
            }
            .font(Typography.ctaButton)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(.bfGradient) : AnyShapeStyle(Color.bfBorder))
            )
            .shadow(color: isEnabled ? Color.bfAccent.opacity(0.24) : Color.clear, radius: 16, y: 6)
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
