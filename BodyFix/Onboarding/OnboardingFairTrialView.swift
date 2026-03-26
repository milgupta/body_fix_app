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
                        .font(Typography.navIcon)
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 12)

                    Text("🎁 Fair Trial Policy")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(Color.bfCardDark.opacity(0.5))
                        )
                        .opacity(showContent ? 1.0 : 0)

                    Color.clear.frame(height: 28)

                    Image("comparison")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 200)
                        .padding(.horizontal, 20)
                        .opacity(showContent ? 1.0 : 0)

                    Color.clear.frame(height: 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Body Fix is Free for You to Try")
                            .font(Typography.question)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(4)
                            .minimumScaleFactor(0.85)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("After your trial, we depend on your support to keep delivering the best evidence-backed tools so you can stay committed to change.")
                            .font(Typography.subtitle)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .opacity(showContent ? 1.0 : 0)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

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
