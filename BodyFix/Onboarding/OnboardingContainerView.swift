import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext

    private var showsNavBar: Bool {
        ![0, 4, 7, 17, 19, 20].contains(viewModel.currentStep)
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
                                    .font(Typography.navIcon)
                                    .foregroundStyle(Color.bfTextPrimary)
                                    .frame(width: 42, height: 42)
                                    .background(Circle().fill(Color.bfSurfaceElevated))
                                    .overlay(Circle().stroke(Color.bfBorder.opacity(0.75), lineWidth: 1))
                            }
                        }

                        ProgressBar(progress: viewModel.progress)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
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
            case 0:  OnboardingWelcomeView()
            case 1:  OnboardingNameView()
            case 2:  OnboardingGoalsView()
            case 3:  OnboardingLongTermGoalView()
            case 4:  OnboardingValidationView()
            case 5:  OnboardingFrequencyView()
            case 6:  OnboardingImpactView()
            case 7:  OnboardingBuildProgramView()
            case 8:  OnboardingProblemAreasView()
            case 9:  OnboardingActivityView()
            case 10: OnboardingLifestyleView()
            case 11: OnboardingProblemTimesView()
            case 12: OnboardingExperienceView()
            case 13: OnboardingDurationView()
            case 14: OnboardingEducationView()
            case 15: OnboardingCommitmentView()
            case 16: OnboardingHealthConditionsView()
            case 17: OnboardingAnalyzingView()
            case 18: OnboardingMotivationLevelView()
            case 19: OnboardingFairTrialView()
            case 20: OnboardingPlanPreviewView()
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
            if [0, 4, 7, 14, 17, 19].contains(step) {
                Rectangle().fill(.bfSplashGradient)
            } else {
                Color.bfPageBackground
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [UserProfile.self, PersonalizedPlan.self, StretchSession.self], inMemory: true)
}
