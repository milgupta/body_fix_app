import SwiftUI

struct OnboardingGoalView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [(emoji: String, title: String)] = [
        ("🩹", "Reduce pain"),
        ("🧘", "Improve flexibility"),
        ("🔄", "Recover faster from workouts"),
        ("🧍", "Improve posture"),
        ("🚶", "Move better during the day"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What matters most to you.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("What do you want to **improve** the most?")
                    .font(Typography.question)
                    .foregroundStyle(.bfTextPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            Spacer()

            VStack(spacing: 12) {
                ForEach(options, id: \.title) { option in
                    OnboardingOptionCard(
                        title: option.title,
                        emoji: option.emoji,
                        isSelected: viewModel.primaryGoal == option.title
                    ) {
                        viewModel.primaryGoal = option.title
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canAdvance) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    viewModel.advance()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        OnboardingGoalView()
    }
    .environment(OnboardingViewModel())
}
