import SwiftUI

struct OnboardingImpactView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let emojis: [Int: String] = [
        1: "😊",
        2: "🙂",
        3: "😐",
        4: "😣",
        5: "😫",
    ]

    var body: some View {
        @Bindable var vm = viewModel

        VStack(alignment: .leading, spacing: 0) {
            Text("How much is tightness or pain **affecting** your daily life?")
                .font(Typography.question)
                .foregroundStyle(.bfTextPrimary)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)

            Spacer(minLength: 40)

            Text(emojis[viewModel.painImpact] ?? "😐")
                .font(.system(size: 72))
                .frame(maxWidth: .infinity)

            Spacer().frame(height: 12)

            SteppedSliderView(
                value: $vm.painImpact,
                range: 1...5,
                labels: [:],
                showValueLabel: false
            )
            .padding(.horizontal, 20)

            HStack {
                Text("Not at all")
                    .font(Typography.caption)
                    .foregroundStyle(.bfTextSecondary)
                Spacer()
                Text("Significantly")
                    .font(Typography.caption)
                    .foregroundStyle(.bfTextSecondary)
            }
            .padding(.horizontal, 34)
            .padding(.top, 8)

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
