import SwiftUI

struct OnboardingNameView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        @Bindable var vm = viewModel

        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("First things first,")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("What should we call you?")
                    .font(Typography.question)
                    .foregroundStyle(.bfTextPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            TextField("", text: $vm.userName)
                .font(Typography.optionText)
                .foregroundStyle(.bfTextPrimary)
                .padding(.horizontal, 20)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.bfCardDark)
                )
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 20)

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canAdvance) {
                isFocused = false
                withAnimation(.easeInOut(duration: 0.35)) {
                    viewModel.advance()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        OnboardingNameView()
    }
    .environment(OnboardingViewModel())
}
