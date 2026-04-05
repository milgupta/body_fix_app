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
                .frame(height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.bfSurfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.bfBorder.opacity(0.78), lineWidth: 1)
                )
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 20)
                .shadow(color: Color.black.opacity(0.03), radius: 10, y: 4)

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.canAdvance) {
                isFocused = false
                withAnimation(.easeInOut(duration: 0.35)) {
                    viewModel.advance()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 44)
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
