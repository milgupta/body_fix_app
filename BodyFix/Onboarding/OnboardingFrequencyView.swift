import SwiftUI

struct OnboardingFrequencyView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Now, let's understand your body a bit more.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("How many **days a week** do you feel stiff or in pain?")
                    .font(Typography.question)
                    .foregroundStyle(.bfTextPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)

            Spacer()

            VStack(spacing: 24) {
                Text("\(viewModel.painFrequency) days")
                    .font(Typography.sliderValue)
                    .foregroundStyle(.bfTextPrimary)

                SteppedSliderView(
                    value: $vm.painFrequency,
                    range: 1...7,
                    labels: [:],
                    showValueLabel: false
                )
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
        OnboardingFrequencyView()
    }
    .environment(OnboardingViewModel())
}
