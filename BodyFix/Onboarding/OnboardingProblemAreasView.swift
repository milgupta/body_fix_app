import SwiftUI

struct OnboardingProblemAreasView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @FocusState private var isOtherFieldFocused: Bool

    var body: some View {
        @Bindable var vm = viewModel

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
                        if area == .other {
                            otherAreaSection(vm: vm)
                        } else {
                            painAreaCard(area)
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

    private func painAreaCard(_ area: OnboardingPainArea) -> some View {
        OnboardingMultiSelectCard(
            title: area.displayName,
            isSelected: viewModel.selectedPainAreas.contains(area)
        ) {
            togglePainArea(area)
        }
    }

    private func otherAreaSection(vm: OnboardingViewModel) -> some View {
        let isSelected = viewModel.selectedPainAreas.contains(.other)

        return VStack(spacing: 10) {
            OnboardingMultiSelectCard(
                title: OnboardingPainArea.other.displayName,
                isSelected: isSelected
            ) {
                togglePainArea(.other)
            }

            if isSelected {
                TextField("Describe where you feel it", text: Binding(
                    get: { vm.problemAreaOtherText },
                    set: { vm.problemAreaOtherText = $0 }
                ))
                .font(Typography.optionText)
                .foregroundStyle(.bfTextPrimary)
                .padding(.horizontal, 20)
                .frame(minHeight: 72)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.bfSurfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.bfBorder.opacity(0.78), lineWidth: 1)
                )
                .focused($isOtherFieldFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .shadow(color: Color.black.opacity(0.03), radius: 10, y: 4)
                .onAppear {
                    isOtherFieldFocused = true
                }
            }
        }
    }

    private func togglePainArea(_ area: OnboardingPainArea) {
        if viewModel.selectedPainAreas.contains(area) {
            viewModel.selectedPainAreas.remove(area)
            if area == .other {
                viewModel.problemAreaOtherText = ""
                isOtherFieldFocused = false
            }
        } else {
            viewModel.selectedPainAreas.insert(area)
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
