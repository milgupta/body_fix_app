import SwiftUI

struct OnboardingProblemAreasView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Let's find your trouble spots.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("Where do you feel **tightness** or discomfort most often?")
                    .font(Typography.question)
                    .foregroundStyle(.bfTextPrimary)

                Text("Select all that apply.")
                    .font(Typography.caption)
                    .foregroundStyle(.bfTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(OnboardingPainArea.allCases) { area in
                        OnboardingMultiSelectCard(
                            title: area.displayName,
                            isSelected: viewModel.selectedPainAreas.contains(area)
                        ) {
                            if viewModel.selectedPainAreas.contains(area) {
                                viewModel.selectedPainAreas.remove(area)
                            } else {
                                viewModel.selectedPainAreas.insert(area)
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
        OnboardingProblemAreasView()
    }
    .environment(OnboardingViewModel())
}
