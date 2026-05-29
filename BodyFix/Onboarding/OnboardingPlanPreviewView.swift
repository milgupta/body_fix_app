import SwiftUI
import SwiftData
import StoreKit

struct OnboardingPlanPreviewView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @State private var showContent = false
    @State private var trialIntroStep: TrialIntroStep?

    private var draftProfile: UserProfile {
        UserProfile(
            name: viewModel.userName,
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
            healthConditions: Array(viewModel.selectedHealthConditions).sorted(),
            onboardingComplete: true
        )
    }

    private var recommendation: PersonalizedPlanRecommendation {
        PersonalizedPlanGenerator.recommendation(for: draftProfile)
    }

    private var displayModel: PersonalizedPlanDisplayModel {
        .from(
            recommendation: recommendation,
            eyebrow: "Built from your answers",
            title: "Your plan is ready"
        )
    }

    var body: some View {
        Group {
            switch trialIntroStep {
            case .tryFree:
                OnboardingTrialTryFreeView {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        trialIntroStep = .reminder
                    }
                }

            case .reminder:
                OnboardingTrialReminderView {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        trialIntroStep = .tryFree
                    }
                } onContinue: {
                    continueThroughTrialIntro()
                }

            case nil:
                planPreview
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }

    private var planPreview: some View {
        ZStack(alignment: .bottom) {
            Color.bfPageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    firstStepCard
                    stretchList
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 166)
            }

            OnboardingContinueButton(label: "Start My Plan", style: .gradientPrimary) {
                HapticManager.shared.success()
                withAnimation(.easeInOut(duration: 0.28)) {
                    trialIntroStep = .tryFree
                }
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

            PersonalizedPlanPreviewHeader(model: displayModel)
        }
        .opacity(showContent ? 1 : 0)
    }

    private var firstStepCard: some View {
        PersonalizedPlanFirstStepCard(
            firstStretch: displayModel.stretches.first,
            title: displayModel.firstStepTitle
        )
        .opacity(showContent ? 1 : 0)
    }

    private var stretchList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your first session")
                .font(Typography.sectionTitle)
                .foregroundStyle(.bfTextPrimary)

            ForEach(Array(displayModel.stretches.enumerated()), id: \.element.id) { index, stretch in
                PersonalizedPlanStretchRow(stretch: stretch, index: index, isFirstStep: index == 0)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(Double(index) * 0.06), value: showContent)
            }
        }
    }

    private func continueThroughTrialIntro() {
        HapticManager.shared.success()
        PaywallManager.shared.presentOnboardingPaywalls {
            finishOnboardingAndEnterApp()
        }
    }

    private func finishOnboardingAndEnterApp() {
        let profile = viewModel.saveProfile(to: modelContext)
        PersonalizedPlanGenerator.upsertPlan(for: profile, existing: nil, in: modelContext)
        try? modelContext.save()
        AnalyticsTracker.capture("onboarding_plan_created")
        if RatingManager.canRequestOnboardingRating() {
            requestReview()
            RatingManager.markReviewRequested(trigger: .onboardingPlan)
        }
    }
}

private enum TrialIntroStep {
    case tryFree
    case reminder
}

private struct OnboardingTrialTryFreeView: View {
    let onTryNow: () -> Void
    @State private var didAppear = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 82)

            Text("We want you to\ntry Body Fix for free.")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Spacer(minLength: 44)

            TrialMockImageStack(isPresented: didAppear)
                .frame(height: 330)

            Spacer(minLength: 18)

            TrialNoPaymentRow()

            TrialPrimaryButton(title: "Try NOW", action: onTryNow)
                .padding(.top, 18)
                .padding(.horizontal, 28)

            Spacer().frame(height: 42)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.82).delay(0.08)) {
                didAppear = true
            }
        }
    }
}

private struct OnboardingTrialReminderView: View {
    let onBack: () -> Void
    let onContinue: () -> Void
    @State private var didAppear = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.ignoresSafeArea()

            Button {
                HapticManager.shared.softImpact()
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(Typography.navIcon)
                    .foregroundStyle(Color.bfTextMuted)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.leading, 24)
            .padding(.top, 44)

            VStack(spacing: 0) {
                Spacer().frame(height: 176)

                Text("We'll send you\na reminder before your\nfree trial ends")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                Spacer().frame(height: 52)

                TrialReminderBell(isPresented: didAppear)

                Spacer(minLength: 86)

                TrialNoPaymentRow()

                TrialPrimaryButton(title: "Continue for FREE", action: onContinue)
                    .padding(.top, 18)
                    .padding(.horizontal, 28)

                Spacer().frame(height: 42)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.78).delay(0.08)) {
                didAppear = true
            }
        }
    }
}

private struct TrialMockImageStack: View {
    let isPresented: Bool

    var body: some View {
        ZStack {
            TrialBundledPNGImage(name: "onboarding_image")
                .frame(width: 190)
                .rotationEffect(.degrees(isPresented ? -9 : -2))
                .offset(x: isPresented ? -76 : 0, y: isPresented ? 26 : 44)
                .scaleEffect(isPresented ? 0.78 : 0.66)
                .opacity(isPresented ? 0.62 : 0)
                .animation(.spring(response: 0.72, dampingFraction: 0.82).delay(0.12), value: isPresented)

            TrialBundledPNGImage(name: "mock_image2")
                .frame(width: 224)
                .rotationEffect(.degrees(isPresented ? 8 : 1))
                .offset(x: isPresented ? 74 : 0, y: isPresented ? 8 : 40)
                .scaleEffect(isPresented ? 0.78 : 0.64)
                .opacity(isPresented ? 0.70 : 0)
                .animation(.spring(response: 0.72, dampingFraction: 0.82).delay(0.2), value: isPresented)

            TrialBundledPNGImage(name: "mock_image1")
                .frame(width: 204)
                .rotationEffect(.degrees(isPresented ? -2 : 0))
                .offset(x: isPresented ? -10 : 0, y: isPresented ? -4 : 34)
                .scaleEffect(isPresented ? 1 : 0.86)
                .opacity(isPresented ? 1 : 0)
                .animation(.spring(response: 0.62, dampingFraction: 0.82).delay(0.04), value: isPresented)
        }
    }
}

private struct TrialBundledPNGImage: View {
    let name: String

    var body: some View {
        Group {
            if let image = Self.image(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
    }

    private static func image(named name: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "images"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}

private struct TrialReminderBell: View {
    let isPresented: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell.fill")
                .font(.system(size: 112, weight: .bold))
                .foregroundStyle(Color.bfAccent.opacity(0.18))
                .scaleEffect(isPresented ? 1 : 0.82)

            Text("1")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.red))
                .offset(x: 28, y: -8)
                .scaleEffect(isPresented ? 1 : 0.72)
        }
        .frame(width: 176, height: 138)
        .opacity(isPresented ? 1 : 0)
    }
}

private struct TrialNoPaymentRow: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .bold))

            Text("No Payment Due Now")
                .font(Typography.sectionTitle)
        }
        .foregroundStyle(Color.black)
    }
}

private struct TrialPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action()
        } label: {
            Text(title)
                .font(Typography.primaryCta)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black)
                )
        }
        .buttonStyle(.plain)
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
