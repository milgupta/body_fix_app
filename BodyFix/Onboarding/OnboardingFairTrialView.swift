import SwiftUI

struct OnboardingFairTrialView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    HapticManager.shared.softImpact()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        viewModel.goBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            Spacer()

            Text("🎁 Fair Trial Policy")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(Color.bfCardDark.opacity(0.5))
                )
                .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 28)

            Image("comparison")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .opacity(showContent ? 1.0 : 0)

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text("Body Fix is Free for You to Try")
                    .font(Typography.question)
                    .foregroundStyle(.white)

                Text("After your trial, we depend on your support to keep delivering the best evidence-backed tools so you can stay committed to change.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 32)

            OnboardingContinueButton(label: "That's fair") {
                withAnimation(.easeInOut(duration: 0.35)) {
                    viewModel.advance()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .opacity(showContent ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.bfSplashGradient.ignoresSafeArea()
        OnboardingFairTrialView()
    }
    .environment(OnboardingViewModel())
}
