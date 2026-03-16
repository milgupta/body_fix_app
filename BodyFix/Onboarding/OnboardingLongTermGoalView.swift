import SwiftUI

struct OnboardingLongTermGoalView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [(emoji: String, title: String)] = [
        ("✅", "Become pain-free"),
        ("📅", "Build a lasting stretch routine"),
        ("🏅", "Improve athletic performance"),
        ("🌱", "Age with mobility and ease"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Got it **\(viewModel.userName)**!")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("What's your **long-term** body goal?")
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
                            isSelected: viewModel.longTermGoal == option.title
                        ) {
                            viewModel.longTermGoal = option.title
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
        OnboardingLongTermGoalView()
    }
    .environment(OnboardingViewModel())
}
