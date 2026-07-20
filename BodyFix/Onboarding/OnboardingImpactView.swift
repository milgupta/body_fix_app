import SwiftUI

struct OnboardingImpactView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        VStack(alignment: .leading, spacing: 0) {
            Text("How much is tightness or pain **affecting** your daily life?")
                .font(Typography.question)
                .foregroundStyle(.bfTextPrimary)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

            Spacer()

            VStack(spacing: 24) {
                Text("\(viewModel.painImpact) out of 5")
                    .font(Typography.sliderValue)
                    .foregroundStyle(.bfTextPrimary)
                    .contentTransition(.numericText(value: Double(viewModel.painImpact)))

                VStack(spacing: 8) {
                    SteppedSliderView(
                        value: $vm.painImpact,
                        range: 1...5,
                        labels: [:],
                        showValueLabel: false
                    )

                    HStack {
                        Text("Not at all")
                        Spacer()
                        Text("Significantly")
                    }
                    .font(Typography.caption)
                    .foregroundStyle(.bfTextSecondary)
                    .padding(.horizontal, 14)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)

            Spacer()

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
        OnboardingImpactView()
    }
    .environment(OnboardingViewModel())
}
