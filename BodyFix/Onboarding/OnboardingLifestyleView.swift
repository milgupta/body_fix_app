import SwiftUI

struct OnboardingLifestyleView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [(emoji: String, title: String)] = [
        ("💻", "Desk work / computer"),
        ("📚", "Student / studying"),
        ("🧍", "Standing job"),
        ("🔨", "Physical labor"),
        ("🏃", "Athlete / sports training"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("This helps us understand your posture.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("What does your **typical day** look like?")
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
                            isSelected: viewModel.lifestyle == option.title
                        ) {
                            viewModel.lifestyle = option.title
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
        OnboardingLifestyleView()
    }
    .environment(OnboardingViewModel())
}
