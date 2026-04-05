import SwiftUI

struct OnboardingMotivationLevelView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [(emoji: String, title: String)] = [
        ("🔥", "Ready to commit"),
        ("💪", "Pretty motivated"),
        ("🤔", "Curious but cautious"),
        ("🧪", "Just exploring"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("So,")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("How motivated are you to work on this **right now**?")
                    .font(Typography.question)
                    .foregroundStyle(.bfTextPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(options, id: \.title) { option in
                        OnboardingOptionCard(
                            title: option.title,
                            emoji: option.emoji,
                            isSelected: viewModel.motivationLevel == option.title
                        ) {
                            viewModel.motivationLevel = option.title
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            OnboardingContinueButton(isEnabled: viewModel.canAdvance) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    viewModel.advance()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        OnboardingMotivationLevelView()
    }
    .environment(OnboardingViewModel())
}
