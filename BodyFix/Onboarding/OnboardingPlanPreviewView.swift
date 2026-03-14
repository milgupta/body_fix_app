import SwiftUI
import SwiftData

struct OnboardingPlanPreviewView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showContent = false

    private var previewStretches: [Stretch] {
        let allStretches = StretchDatabase.loadAll()
        let userAreas = viewModel.selectedPainAreas.map(\.rawValue)
        let matched = allStretches.filter { stretch in
            stretch.targetRegions.contains(where: { userAreas.contains($0) })
        }
        return Array(matched.isEmpty ? allStretches : matched).prefix(3).map { $0 }
    }

    private var totalDuration: Int {
        previewStretches.reduce(0) { $0 + $1.holdDuration }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 24)

            Text("Your Body Fix Plan")
                .font(Typography.splashTitle)
                .foregroundStyle(.bfTextPrimary)
                .padding(.horizontal, 20)
                .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 8)

            Text("Daily routine: \(totalDuration / 60) min \(totalDuration % 60)s")
                .font(Typography.subtitle)
                .foregroundStyle(.bfTextSecondary)
                .padding(.horizontal, 20)
                .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 28)

            VStack(spacing: 12) {
                ForEach(Array(previewStretches.enumerated()), id: \.element.id) { index, stretch in
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.bfSelectionGradient)
                            .frame(width: 48, height: 48)
                            .overlay {
                                Text("\(index + 1)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(stretch.name)
                                .font(Typography.optionText)
                                .foregroundStyle(.bfTextPrimary)

                            Text("\(stretch.holdDuration)s · \(stretch.repScheme)")
                                .font(Typography.caption)
                                .foregroundStyle(.bfTextSecondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.bfCardDark)
                    )
                    .opacity(showContent ? 1.0 : 0)
                    .animation(
                        .easeOut(duration: 0.5).delay(Double(index) * 0.15),
                        value: showContent
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            OnboardingContinueButton(label: "Start My Plan") {
                viewModel.saveProfile(to: modelContext)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .opacity(showContent ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        OnboardingPlanPreviewView()
    }
    .environment(OnboardingViewModel())
    .modelContainer(for: [UserProfile.self, StretchSession.self], inMemory: true)
}
