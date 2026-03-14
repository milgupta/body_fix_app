import SwiftUI

struct OnboardingProblemTimesView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [(emoji: String, title: String)] = [
        ("🌅", "Morning stiffness"),
        ("🪑", "After sitting long periods"),
        ("🏋️", "After workouts"),
        ("🌙", "Before bed"),
        ("⏰", "All day"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Almost there.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("When do you feel the **tightness** the most?")
                    .font(Typography.question)
                    .foregroundStyle(.bfTextPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            Spacer()

            VStack(spacing: 12) {
                ForEach(options, id: \.title) { option in
                    OnboardingMultiSelectCard(
                        title: option.title,
                        emoji: option.emoji,
                        isSelected: viewModel.selectedProblemTimes.contains(option.title)
                    ) {
                        if viewModel.selectedProblemTimes.contains(option.title) {
                            viewModel.selectedProblemTimes.remove(option.title)
                        } else {
                            viewModel.selectedProblemTimes.insert(option.title)
                        }
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
        OnboardingProblemTimesView()
    }
    .environment(OnboardingViewModel())
}
