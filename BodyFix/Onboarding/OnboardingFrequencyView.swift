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
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: OnboardingSeverityLayout.headerHeight, alignment: .top)

            VStack(spacing: 24) {
                OnboardingSeverityBadge(
                    text: "\(viewModel.painFrequency) days",
                    value: viewModel.painFrequency,
                    range: 1...7,
                    accessibilityText: "\(viewModel.painFrequency) days per week"
                )

                VStack(spacing: 8) {
                    SteppedSliderView(
                        value: $vm.painFrequency,
                        range: 1...7,
                        labels: [:],
                        showValueLabel: false
                    )

                    Color.clear
                        .frame(height: OnboardingSeverityLayout.lowerCaptionHeight)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, OnboardingSeverityLayout.controlsTopSpacing)

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
