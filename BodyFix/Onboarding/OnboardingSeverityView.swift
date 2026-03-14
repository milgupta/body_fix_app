import SwiftUI

struct OnboardingSeverityView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private var silhouetteTint: Color {
        let t = Double(viewModel.tightnessSeverity - 1) / 4.0
        return Color(
            red: t * 1.0 + (1 - t) * 0.0,
            green: t * 0.42 + (1 - t) * 0.79,
            blue: t * 0.21 + (1 - t) * 0.65
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Let's gauge where you're at.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("How **tight** does your body feel most days?")
                    .font(Typography.question)
                    .foregroundStyle(.bfTextPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            Spacer()

            BodySilhouetteView(
                highlightedRegions: viewModel.selectedPainAreas,
                tintColor: silhouetteTint
            )
            .frame(width: 140, height: 350)
            .frame(maxWidth: .infinity)

            Spacer()

            @Bindable var vm = viewModel
            SteppedSliderView(value: $vm.tightnessSeverity)
                .padding(.horizontal, 20)

            Spacer().frame(height: 24)

            OnboardingContinueButton {
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
        OnboardingSeverityView()
    }
    .environment(OnboardingViewModel())
}
