import SwiftUI

struct OnboardingGoalsView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [(emoji: String, title: String)] = [
        ("🩹", "Reduce pain and stiffness"),
        ("🧘", "Improve Flexibility"),
        ("🧍", "Improve posture"),
        ("🔄", "Recover faster from workouts"),
        ("😌", "Reduce stress and tension"),
        ("💤", "Sleep better"),
        ("🚶", "Move better day to day"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("So tell us **\(viewModel.userName)**,")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("What do you want Body Fix to **help with** first?")
                    .font(Typography.question)
                    .foregroundStyle(.bfTextPrimary)

                Text("Choose up to 3.")
                    .font(Typography.caption)
                    .foregroundStyle(.bfTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(options, id: \.title) { option in
                        let isSelected = viewModel.selectedBodyGoals.contains(option.title)
                        OnboardingMultiSelectCard(
                            title: option.title,
                            emoji: option.emoji,
                            isSelected: isSelected,
                            canToggle: isSelected || viewModel.selectedBodyGoals.count < 3
                        ) {
                            if isSelected {
                                viewModel.selectedBodyGoals.remove(option.title)
                            } else if viewModel.selectedBodyGoals.count < 3 {
                                viewModel.selectedBodyGoals.insert(option.title)
                            }
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
        OnboardingGoalsView()
    }
    .environment(OnboardingViewModel())
}
