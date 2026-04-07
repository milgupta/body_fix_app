import SwiftUI

struct OnboardingEducationView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var showContent = false

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset: CGFloat = 24
            let maxImageWidth = min(320, proxy.size.width - horizontalInset * 2)
            let maxImageHeight = proxy.size.height * 0.38
            let bottomPad = max(24, proxy.safeAreaInsets.bottom + 16)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                Image("beforevafter")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: maxImageWidth, maxHeight: maxImageHeight)
                    .opacity(showContent ? 1.0 : 0)
                    .scaleEffect(showContent ? 1 : 0.96)

                Spacer().frame(height: 20)

                Text("Your muscles adapt to the positions you spend the most time in.")
                    .font(Typography.splashTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)
                    .opacity(showContent ? 1.0 : 0)

                Spacer(minLength: 0)

                OnboardingContinueButton {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        viewModel.advance()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, bottomPad)
                .opacity(showContent ? 1.0 : 0)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
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
