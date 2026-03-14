import SwiftUI

struct OnboardingActivityView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [(emoji: String, title: String)] = [
        ("🪑", "Mostly sitting (desk / school / driving)"),
        ("🚶", "Lightly active (walking, errands)"),
        ("🏋️", "Moderately active (workouts a few times/week)"),
        ("⚡", "Very active (daily training / sports)"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Good to know.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("How **active** is your typical day?")
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
                        isSelected: viewModel.activityLevel == option.title
                    ) {
                        viewModel.activityLevel = option.title
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
        OnboardingActivityView()
    }
    .environment(OnboardingViewModel())
}
