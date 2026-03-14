import SwiftUI

struct OnboardingDurationView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [(emoji: String, title: String)] = [
        ("⏱️", "3 minutes"),
        ("🕐", "5 minutes"),
        ("🕙", "10 minutes"),
        ("🕒", "15+ minutes"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Every minute counts.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("How much **time** can you dedicate to your body each day?")
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
                        isSelected: viewModel.dailyTime == option.title
                    ) {
                        viewModel.dailyTime = option.title
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
        OnboardingDurationView()
    }
    .environment(OnboardingViewModel())
}
