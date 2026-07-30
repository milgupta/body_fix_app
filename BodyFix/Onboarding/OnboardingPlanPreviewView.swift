import SwiftUI
import SwiftData

struct OnboardingPlanPreviewView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var onboardingPreviewStretch: Stretch?
    @State private var completedPreviewStretchId: String?
    @State private var previewCardPulse = false

    private var draftProfile: UserProfile {
        UserProfile(
            name: viewModel.userName,
            ageRange: viewModel.ageRange,
            bodyGoals: Array(viewModel.selectedBodyGoals),
            longTermGoal: viewModel.longTermGoal,
            painFrequency: viewModel.painFrequency,
            painImpact: viewModel.painImpact,
            activityLevel: viewModel.activityLevel,
            lifestyle: viewModel.lifestyle,
            stretchingFrequency: viewModel.stretchingFrequency,
            dailyTime: viewModel.dailyTime,
            problemAreas: viewModel.problemAreasForProfile,
            problemTimes: Array(viewModel.selectedProblemTimes),
            commitmentDays: viewModel.commitmentDays,
            onboardingComplete: true
        )
    }

    private var recommendation: PersonalizedPlanRecommendation {
        PersonalizedPlanGenerator.recommendation(for: draftProfile)
    }

    private var displayModel: PersonalizedPlanDisplayModel {
        .from(recommendation: recommendation)
    }

    var body: some View {
        planPreview
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    showContent = true
                }
                startPreviewCardPulseIfNeeded()
            }
            .onChange(of: reduceMotion) { _, _ in startPreviewCardPulseIfNeeded() }
            .fullScreenCover(item: $onboardingPreviewStretch) { stretch in
                OnboardingStretchPreviewContainer(
                    stretch: stretch,
                    onComplete: {
                        completedPreviewStretchId = stretch.id
                        previewCardPulse = false
                        AnalyticsTracker.capture(
                            "onboarding_stretch_preview_completed",
                            properties: ["stretch_id": stretch.id]
                        )
                        onboardingPreviewStretch = nil
                    },
                    onCancel: {
                        AnalyticsTracker.capture(
                            "onboarding_stretch_preview_exited_early",
                            properties: ["stretch_id": stretch.id]
                        )
                        onboardingPreviewStretch = nil
                    }
                )
            }
    }

    private var planPreview: some View {
        ZStack(alignment: .bottom) {
            Color.bfPageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    stretchList
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 166)
            }

            OnboardingContinueButton(label: "Unlock My Plan", style: .gradientPrimary, feedback: .success) {
                continueToPaywall()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 26)
            .opacity(showContent ? 1 : 0)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
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
                .buttonStyle(.plain)

                Spacer()
            }

            PersonalizedPlanSpotlightCard(
                model: displayModel,
                profile: draftProfile
            )
        }
        .opacity(showContent ? 1 : 0)
    }

    private var stretchList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your first session")
                .font(Typography.sectionTitle)
                .foregroundStyle(.bfTextPrimary)

            ForEach(Array(displayModel.stretches.enumerated()), id: \.element.id) { index, stretch in
                if index == 0 {
                    onboardingPreviewRow(stretch)
                } else {
                    PersonalizedPlanStretchRow(stretch: stretch, isFirstStep: false)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.45).delay(Double(index) * 0.06), value: showContent)
                }
            }
        }
    }

    private func onboardingPreviewRow(_ stretch: Stretch) -> some View {
        let didComplete = completedPreviewStretchId == stretch.id
        let shouldPulse = !reduceMotion && !didComplete && onboardingPreviewStretch == nil

        return Button {
            HapticManager.shared.mediumImpact()
            let event = didComplete
                ? "onboarding_stretch_preview_replayed"
                : "onboarding_stretch_preview_started"
            AnalyticsTracker.capture(event, properties: ["stretch_id": stretch.id])
            onboardingPreviewStretch = stretch
        } label: {
            PersonalizedPlanStretchRow(
                stretch: stretch,
                isFirstStep: true,
                firstStepLabel: didComplete ? "Completed · Try again" : "Try this stretch",
                firstStepSystemImage: didComplete ? "checkmark.circle.fill" : "play.fill"
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.bfAccent.opacity(shouldPulse && previewCardPulse ? 0.72 : 0.18), lineWidth: 2)
            )
            .shadow(
                color: Color.bfAccent.opacity(shouldPulse && previewCardPulse ? 0.22 : 0),
                radius: 14,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(shouldPulse && previewCardPulse ? 0.985 : 1)
        .opacity(showContent ? 1 : 0)
        .animation(.easeOut(duration: 0.45), value: showContent)
        .accessibilityLabel(didComplete ? "Try \(stretch.name) again" : "Try \(stretch.name)")
        .accessibilityHint("Opens a preview of the first stretch in your plan")
    }

    private func startPreviewCardPulseIfNeeded() {
        guard !reduceMotion, completedPreviewStretchId == nil else {
            previewCardPulse = false
            return
        }

        previewCardPulse = false
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            previewCardPulse = true
        }
    }

    private func continueToPaywall() {
        HapticManager.shared.success()
        Task {
            await TrackingConsentManager.requestIfNeeded()
            PaywallManager.shared.presentOnboardingPaywalls {
                finishOnboardingAndEnterApp()
            }
        }
    }

    private func finishOnboardingAndEnterApp() {
        AnalyticsTracker.capture(
            AnalyticsEvent.onboardingStepCompleted,
            properties: viewModel.analyticsProperties(for: 20)
        )
        AnalyticsTracker.capture(
            AnalyticsEvent.onboardingCompleted,
            properties: [
                "total_steps": viewModel.totalSteps,
                "age_range": viewModel.ageRange,
            ]
        )
        let profile = viewModel.saveProfile(to: modelContext)
        PersonalizedPlanGenerator.upsertPlan(for: profile, existing: nil, in: modelContext)
        try? modelContext.save()
        viewModel.clearDraft()
        AnalyticsTracker.capture(
            "onboarding_plan_created",
            properties: [
                "age_range": viewModel.ageRange,
                "total_steps": viewModel.totalSteps,
            ]
        )
    }
}

private struct OnboardingStretchPreviewContainer: View {
    let stretch: Stretch
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var path = NavigationPath()
    @State private var tabBarVisibility = TabBarVisibility()

    var body: some View {
        NavigationStack(path: $path) {
            StretchTimerView(
                route: StretchTimerRoute(
                    stretchIds: [stretch.id],
                    startIndex: 0,
                    showsStartCountdown: true,
                    context: .onboardingPreview,
                    source: .onboardingPreview
                ),
                path: $path,
                onOnboardingPreviewComplete: onComplete,
                onOnboardingPreviewCancel: onCancel
            )
        }
        .environment(tabBarVisibility)
        .interactiveDismissDisabled()
    }
}

#Preview {
    ZStack {
        Color.bfPageBackground.ignoresSafeArea()
        OnboardingPlanPreviewView()
    }
    .environment(OnboardingViewModel())
    .modelContainer(for: [UserProfile.self, PersonalizedPlan.self, StretchSession.self], inMemory: true)
}
