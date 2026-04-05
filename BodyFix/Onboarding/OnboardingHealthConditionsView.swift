import SwiftUI

struct OnboardingHealthConditionsView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let options: [String] = [
        "Arthritis",
        "Chronic Pain",
        "Dizziness",
        "Fibromyalgia",
        "Heart Condition",
        "Herniated Disc",
        "High Blood Pressure",
        "Injury",
        "Osteoporosis",
        "Pregnancy",
        "Sciatica",
        "Surgery",
        "Vertigo",
    ]

    private var ctaLabel: String {
        viewModel.selectedHealthConditions.isEmpty ? "Skip" : "Continue"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Safety first.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.bfTextSecondary)

                Text("Do you have any **health conditions** or concerns?")
                    .font(Typography.question)
                    .foregroundStyle(.bfTextPrimary)

                Text("Optional. Select any that matter, or skip for now.")
                    .font(Typography.caption)
                    .foregroundStyle(.bfTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(options, id: \.self) { title in
                        let isSelected = viewModel.selectedHealthConditions.contains(title)
                        OnboardingMultiSelectCard(
                            title: title,
                            emoji: "",
                            isSelected: isSelected
                        ) {
                            if isSelected {
                                viewModel.selectedHealthConditions.remove(title)
                            } else {
                                viewModel.selectedHealthConditions.insert(title)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            OnboardingContinueButton(label: ctaLabel, isEnabled: true) {
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
        OnboardingHealthConditionsView()
    }
    .environment(OnboardingViewModel())
}
