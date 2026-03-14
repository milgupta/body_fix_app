import SwiftUI

struct OnboardingCommitmentView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [(emoji: String, title: String)] = [
        ("📅", "3 days"),
        ("💪", "4 days"),
        ("🔥", "5 days"),
        ("✅", "Every day"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Consistency matters more than intensity.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("How many **days per week** can you realistically commit?")
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
                        isSelected: viewModel.commitmentDays == option.title
                    ) {
                        viewModel.commitmentDays = option.title
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
        OnboardingCommitmentView()
    }
    .environment(OnboardingViewModel())
}
