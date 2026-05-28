import SwiftUI
import SwiftData
import StoreKit

struct OnboardingPlanPreviewView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @State private var showContent = false

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

    private var previewStretches: [Stretch] {
        recommendation.stretches
    }

    var body: some View {
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

            OnboardingContinueButton(label: "Start My Plan") {
                HapticManager.shared.success()
                let profile = viewModel.saveProfile(to: modelContext)
                PersonalizedPlanGenerator.upsertPlan(for: profile, existing: nil, in: modelContext)
                try? modelContext.save()
                AnalyticsTracker.capture("onboarding_plan_created")
                if RatingManager.canRequestOnboardingRating() {
                    requestReview()
                    RatingManager.markReviewRequested(trigger: .onboardingPlan)
                }
                PaywallManager.shared.requestPaywallAfterOnboarding()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 26)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
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

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Built from your answers")
                        .font(Typography.metadataBadge)
                        .foregroundStyle(Color.bfAccent)
                        .lineLimit(1)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.78))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.bfAccent.opacity(0.18), lineWidth: 1)
                        )

                    Text("Your plan is ready")
                        .font(Typography.screenTitle)
                        .foregroundStyle(.bfTextPrimary)

                    Text(headerSummary)
                        .font(Typography.screenSubtitle)
                        .foregroundStyle(.bfTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                headerBadges
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(headerPanel)
        }
        .opacity(showContent ? 1 : 0)
    }

    private var firstStepCard: some View {
        HStack(spacing: 14) {
            if let firstStretch = previewStretches.first {
                BodyFixThumbnailView(stretch: firstStretch, size: 50)
            } else {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color.bfAccent))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Today's first step")
                    .font(Typography.metadataBadge)
                    .foregroundStyle(Color.bfAccent)

                Text(firstStepTitle)
                    .font(Typography.controlLabel)
                    .foregroundStyle(Color.bfTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Begin here. We'll guide you through each hold.")
                    .font(Typography.caption)
                    .foregroundStyle(Color.bfTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Text(planDurationLabel(recommendation.totalSeconds))
                .font(Typography.metadataBadge)
                .foregroundStyle(Color.bfAccent)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.bfAccent.opacity(0.1)))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.bfAccent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 10, y: 4)
        .opacity(showContent ? 1 : 0)
    }

    private var headerBadges: some View {
        HStack(spacing: 10) {
            previewBadge(title: "\(previewStretches.count) stretches", allowsCompression: false)
            previewBadge(title: planDurationLabel(recommendation.totalSeconds), allowsCompression: false)

            if let firstArea = recommendation.focusAreas.first {
                previewBadge(title: firstArea)
            }

            if recommendation.focusAreas.count > 1 {
                previewBadge(title: "\(recommendation.focusAreas.count - 1)+")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerPanel: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "#F5FAFF"),
                        Color(hex: "#EAF3FF"),
                        Color.bfSurfaceElevated.opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Color.bfAccent.opacity(0.16))
                    .frame(width: 168, height: 168)
                    .blur(radius: 22)
                    .offset(x: -48, y: -58)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.bfBlue.opacity(0.12))
                    .frame(width: 128, height: 128)
                    .blur(radius: 24)
                    .offset(x: 42, y: 42)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.bfAccent.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: Color.bfAccent.opacity(0.08), radius: 18, y: 8)
    }

    private var stretchList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your first session")
                .font(Typography.sectionTitle)
                .foregroundStyle(.bfTextPrimary)

            ForEach(Array(previewStretches.enumerated()), id: \.element.id) { index, stretch in
                OnboardingPlanRow(stretch: stretch, index: index, isFirstStep: index == 0)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(Double(index) * 0.06), value: showContent)
            }
        }
    }

    private func previewBadge(title: String, allowsCompression: Bool = true) -> some View {
        Text(title)
            .font(Typography.caption)
            .foregroundStyle(Color.bfAccent)
            .lineLimit(1)
            .truncationMode(.tail)
            .fixedSize(horizontal: !allowsCompression, vertical: false)
            .layoutPriority(allowsCompression ? 0 : 1)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.86))
            )
            .overlay(
                Capsule()
                    .stroke(Color.bfAccent.opacity(0.18), lineWidth: 1)
            )
    }

    private func planDurationLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes > 0 && remainder > 0 { return "\(minutes)m \(remainder)s" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(remainder)s"
    }

    private var headerSummary: String {
        let duration = planDurationLabel(recommendation.totalSeconds)
        let areaPhrase = recommendation.focusAreas.first.map { $0.lowercased() }

        if let areaPhrase {
            return "Start with a \(duration) routine built for your \(areaPhrase) needs and daily rhythm."
        }
        return "Start with a \(duration) routine built from what you told us."
    }

    private var firstStepTitle: String {
        previewStretches.first?.name ?? "Start your first stretch"
    }

}

private struct OnboardingPlanRow: View {
    let stretch: Stretch
    let index: Int
    let isFirstStep: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isFirstStep ? Color.bfAccent.opacity(0.12) : Color.bfSurfaceMuted)
                    .frame(width: 28, height: 28)

                Text("\(index + 1)")
                    .font(Typography.metadataBadge)
                    .foregroundStyle(Color.bfAccent)
            }

            BodyFixThumbnailView(stretch: stretch, size: 52)

            VStack(alignment: .leading, spacing: 5) {
                if isFirstStep {
                    Text("Start here")
                        .font(Typography.metadataBadge)
                        .foregroundStyle(Color.bfAccent)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.bfAccent.opacity(0.1)))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(stretch.name)
                        .font(Typography.controlLabel)
                        .foregroundStyle(.bfTextPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(timingLabel)
                        .font(Typography.caption)
                        .foregroundStyle(.bfTextSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isFirstStep ? Color.bfAccent.opacity(0.28) : Color.bfBorder.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isFirstStep ? 0.035 : 0.02), radius: isFirstStep ? 10 : 8, y: 3)
    }

    private var timingLabel: String {
        let duration = "\(stretch.duration)s"
        if stretch.repScheme.hasPrefix(duration) {
            return stretch.repScheme
        }
        return "\(duration) · \(stretch.repScheme)"
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
