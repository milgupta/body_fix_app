import SwiftUI

struct OnboardingEducationView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 32)

            Image("beforevafter")
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 240)
                .opacity(showContent ? 1.0 : 0)
                .scaleEffect(showContent ? 1 : 0.96)

            Spacer().frame(height: 28)

            Text("Your muscles adapt to the positions you spend the most time in.")
                .font(Typography.splashTitle)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
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
