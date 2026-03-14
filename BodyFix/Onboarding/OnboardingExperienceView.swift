import SwiftUI

struct OnboardingExperienceView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [(emoji: String, title: String)] = [
        ("🚫", "Never"),
        ("🤷", "Occasionally"),
        ("📅", "1–2 times per week"),
        ("💪", "Several times per week"),
        ("✅", "Daily"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("No judgment here.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("How often do you currently **stretch**?")
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
                        isSelected: viewModel.stretchingFrequency == option.title
                    ) {
                        viewModel.stretchingFrequency = option.title
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
        OnboardingExperienceView()
    }
    .environment(OnboardingViewModel())
}
