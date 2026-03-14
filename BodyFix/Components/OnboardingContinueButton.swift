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
            HStack(spacing: 6) {
                Text(label)
                Image(systemName: "arrow.right")
            }
            .font(Typography.ctaButton)
            .foregroundStyle(.bfTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.bfCardDarker)
            )
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.4)
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
