import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var stepEnteredAt = Date()
    @State private var hasTrackedInitialStep = false
    @State private var wasBackgrounded = false
    @State private var painProfileSubmissionCount = 0

    private var showsNavBar: Bool {
        ![0, 4, 7, 16, 19].contains(viewModel.currentStep)
    }

    private var showsBackButton: Bool {
        viewModel.currentStep > 0
    }

    var body: some View {
        ZStack {
            backgroundForStep(viewModel.currentStep)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if showsNavBar {
                    HStack(spacing: 16) {
                        if showsBackButton {
                            Button {
                                HapticManager.shared.softImpact()
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    viewModel.goBack()
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(Typography.navIcon)
                                    .foregroundStyle(Color.bfTextPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Color.bfSurfaceElevated)
                                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.bfBorder.opacity(0.55), lineWidth: 1)
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        ProgressBar(progress: viewModel.progress)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 18)
                }

                screenContent
                    .animation(.easeInOut(duration: 0.35), value: viewModel.currentStep)
            }
        }
        .environment(viewModel)
        .onAppear {
            HapticManager.shared.prepare()
            guard !hasTrackedInitialStep else { return }
            hasTrackedInitialStep = true
            stepEnteredAt = Date()
            AnalyticsTracker.capture(AnalyticsEvent.onboardingStarted)
            trackStepViewed(viewModel.currentStep, direction: "initial")
        }
        .onChange(of: viewModel.currentStep) { oldStep, newStep in
            trackStepChange(from: oldStep, to: newStep)
        }
        .onChange(of: scenePhase) { _, newPhase in
            trackScenePhase(newPhase)
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
            case 16: OnboardingAnalyzingView()
            case 17: OnboardingSignatureView()
            case 18: OnboardingMotivationLevelView()
            case 19: OnboardingPlanPreviewView()
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
            if [0, 4, 7, 14, 16].contains(step) {
                Rectangle().fill(.bfSplashGradient)
            } else {
                Color.bfPageBackground
            }
        }
    }

    private func trackStepChange(from oldStep: Int, to newStep: Int) {
        let now = Date()
        let duration = max(0, now.timeIntervalSince(stepEnteredAt))

        if newStep > oldStep {
            var properties = viewModel.analyticsProperties(for: oldStep)
            properties["duration_seconds"] = duration
            properties["destination_step_id"] = OnboardingViewModel.stepIdentifiers.indices.contains(newStep)
                ? OnboardingViewModel.stepIdentifiers[newStep]
                : "unknown"
            AnalyticsTracker.capture(AnalyticsEvent.onboardingStepCompleted, properties: properties)

            if oldStep == 8 {
                trackPainProfile()
            }
        } else if newStep < oldStep {
            var properties = viewModel.analyticsProperties(for: oldStep)
            properties["duration_seconds"] = duration
            properties["destination_step_id"] = OnboardingViewModel.stepIdentifiers.indices.contains(newStep)
                ? OnboardingViewModel.stepIdentifiers[newStep]
                : "unknown"
            AnalyticsTracker.capture(AnalyticsEvent.onboardingBackTapped, properties: properties)
        }

        stepEnteredAt = now
        trackStepViewed(newStep, direction: newStep > oldStep ? "forward" : "back")
    }

    private func trackStepViewed(_ step: Int, direction: String) {
        var properties = viewModel.analyticsProperties(for: step)
        properties["entry_direction"] = direction
        AnalyticsTracker.capture(AnalyticsEvent.onboardingStepViewed, properties: properties)
    }

    private func trackPainProfile() {
        painProfileSubmissionCount += 1
        let areas = viewModel.selectedPainAreas
            .map(\.analyticsID)
            .sorted()
        let sharedProperties: [String: Any] = [
            "problem_areas": areas,
            "problem_area_count": areas.count,
            "pain_frequency_days": viewModel.painFrequency,
            "pain_impact_score": viewModel.painImpact,
            "includes_other": viewModel.selectedPainAreas.contains(.other),
            "submission_number": painProfileSubmissionCount,
        ]

        AnalyticsTracker.capture(
            AnalyticsEvent.onboardingPainProfileSubmitted,
            properties: sharedProperties
        )

        for area in areas {
            var properties = sharedProperties
            properties.removeValue(forKey: "problem_areas")
            properties["area_id"] = area
            AnalyticsTracker.capture(
                AnalyticsEvent.onboardingProblemAreaSelected,
                properties: properties
            )
        }
    }

    private func trackScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background:
            var properties = viewModel.analyticsProperties()
            properties["duration_seconds"] = max(0, Date().timeIntervalSince(stepEnteredAt))
            AnalyticsTracker.capture(AnalyticsEvent.onboardingBackgrounded, properties: properties)
            wasBackgrounded = true
        case .active where wasBackgrounded:
            AnalyticsTracker.capture(
                AnalyticsEvent.onboardingResumed,
                properties: viewModel.analyticsProperties()
            )
            wasBackgrounded = false
        default:
            break
        }
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [UserProfile.self, PersonalizedPlan.self, StretchSession.self], inMemory: true)
}
