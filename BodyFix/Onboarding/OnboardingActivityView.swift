import SwiftUI

struct OnboardingActivityView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [String] = [
        "Mostly sitting",
        "Mixed movement",
        "Lightly active",
        "Moderately active",
        "Very active",
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

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(options, id: \.self) { option in
                        OnboardingOptionCard(
                            title: option,
                            isSelected: viewModel.activityLevel == option
                        ) {
                            viewModel.activityLevel = option
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
        OnboardingActivityView()
    }
    .environment(OnboardingViewModel())
}
