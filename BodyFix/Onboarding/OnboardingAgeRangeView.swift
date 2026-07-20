import SwiftUI

struct OnboardingAgeRangeView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options = [
        "Below 18",
        "18–24",
        "25–34",
        "35–44",
        "45–54",
        "55–64",
        "65+",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Thanks, **\(viewModel.userName)**.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("What’s your **age range**?")
                    .font(Typography.question)
                    .foregroundStyle(.bfTextPrimary)

                Text("This helps us craft a custom routine that fits your body.")
                    .font(Typography.caption)
                    .foregroundStyle(.bfTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(options, id: \.self) { option in
                        OnboardingOptionCard(
                            title: option,
                            isSelected: viewModel.ageRange == option
                        ) {
                            viewModel.ageRange = option
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    let viewModel = OnboardingViewModel()
    viewModel.userName = "Milan"

    return ZStack {
        Color.bfPageBackground.ignoresSafeArea()
        OnboardingAgeRangeView()
    }
    .environment(viewModel)
}
