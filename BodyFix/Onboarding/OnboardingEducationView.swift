import SwiftUI

struct OnboardingEducationView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "figure.stand")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.9))
                .padding(40)
                .background(
                    Circle()
                        .fill(.white.opacity(0.15))
                )
                .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 40)

            VStack(spacing: 16) {
                Text("Your muscles adapt to the positions you spend the most time in.")
                    .font(Typography.splashTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Sitting shortens hip flexors and weakens the back. A few minutes of targeted stretching daily can restore balance.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .opacity(showContent ? 1.0 : 0)

            Spacer()

            OnboardingContinueButton {
                withAnimation(.easeInOut(duration: 0.35)) {
                    viewModel.advance()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .opacity(showContent ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.bfSplashGradient.ignoresSafeArea()
        OnboardingEducationView()
    }
    .environment(OnboardingViewModel())
}
