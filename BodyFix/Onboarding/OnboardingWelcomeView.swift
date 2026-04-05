import SwiftUI

struct OnboardingWelcomeView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var showContent = false
    @State private var pulseCTA = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.white.opacity(0.24),
                    Color.white.opacity(0.06),
                    Color.clear,
                ],
                center: .top,
                startRadius: 60,
                endRadius: 480
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: 120, y: -220)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.88)

            VStack(spacing: 0) {
                Spacer(minLength: 32)

                OnboardingHeroPreview()
                    .scaleEffect(showContent ? 1 : 0.94)
                    .offset(y: showContent ? 0 : 28)
                    .opacity(showContent ? 1.0 : 0)
                    .animation(.spring(response: 0.82, dampingFraction: 0.9), value: showContent)

                Spacer(minLength: 22)

                VStack(spacing: 10) {
                    Text("Your body is telling you something.")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Body Fix listens.")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                }
                .padding(.horizontal, 28)
                .offset(y: showContent ? 0 : 16)
                .opacity(showContent ? 1.0 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.12), value: showContent)

                Spacer().frame(height: 24)

                OnboardingContinueButton(label: "Start Feeling Better") {
                    HapticManager.shared.mediumImpact()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        viewModel.advance()
                    }
                }
                .padding(.horizontal, 20)
                .scaleEffect(pulseCTA ? 0.975 : 1.0)
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 12)
                .animation(.easeOut(duration: 0.55).delay(0.22), value: showContent)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulseCTA)
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.78, dampingFraction: 0.88)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                pulseCTA = true
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
