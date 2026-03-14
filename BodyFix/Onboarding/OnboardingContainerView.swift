import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext

    private var showsNavBar: Bool {
        ![0, 11, 12].contains(viewModel.currentStep)
    }

    var body: some View {
        ZStack {
            backgroundForStep(viewModel.currentStep)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if showsNavBar {
                    HStack(spacing: 16) {
                        if viewModel.currentStep > 0 {
                            Button {
                                HapticManager.shared.softImpact()
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    viewModel.goBack()
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }

                        ProgressBar(progress: viewModel.progress)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }

                screenContent
                    .animation(.easeInOut(duration: 0.35), value: viewModel.currentStep)
            }
        }
        .environment(viewModel)
        .onAppear {
            HapticManager.shared.prepare()
        }
    }

    @ViewBuilder
    private var screenContent: some View {
        Group {
            switch viewModel.currentStep {
            case 0: OnboardingWelcomeView()
            case 1: OnboardingProblemAreasView()
            case 2: OnboardingActivityView()
            case 3: OnboardingLifestyleView()
            case 4: OnboardingSeverityView()
            case 5: OnboardingProblemTimesView()
            case 6: OnboardingExperienceView()
            case 7: OnboardingGoalView()
            case 8: OnboardingDurationView()
            case 9: OnboardingEducationView()
            case 10: OnboardingCommitmentView()
            case 11: OnboardingAnalyzingView()
            case 12: OnboardingPlanPreviewView()
            default: EmptyView()
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
    }

    private func backgroundForStep(_ step: Int) -> some View {
        Group {
            if [0, 9, 11].contains(step) {
                Rectangle().fill(.bfSplashGradient)
            } else {
                Color.bfNavy
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [UserProfile.self, StretchSession.self], inMemory: true)
}
