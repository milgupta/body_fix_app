import SwiftUI

struct OnboardingWelcomeView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            BodySilhouetteView(tintColor: .white)
                .frame(width: 160, height: 400)
                .opacity(showContent ? 1.0 : 0)

            Spacer()

            VStack(spacing: 12) {
                Text("Most people carry hidden tension\nin their body.")
                    .font(Typography.splashTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Body Fix helps you identify and relieve it\nin minutes a day.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 40)

            OnboardingContinueButton(label: "Start Body Scan") {
                withAnimation(.easeInOut(duration: 0.35)) {
                    viewModel.advance()
                }
            }
            .padding(.horizontal, 20)
            .opacity(showContent ? 1.0 : 0)
        }
        .padding(.bottom, 40)
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
        OnboardingWelcomeView()
    }
    .environment(OnboardingViewModel())
}
