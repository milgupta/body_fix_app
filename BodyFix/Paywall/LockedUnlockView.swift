import SwiftUI
import SwiftData

struct LockedUnlockView: View {
    @Query private var profiles: [UserProfile]
    @Query private var plans: [PersonalizedPlan]
    @AppStorage(PaywallManager.showPaywallAfterOnboardingKey) private var showPaywallAfterOnboarding = false
    @AppStorage("show_reminder_prompt_after_subscription") private var showReminderPromptAfterSubscription = false
    @State private var showPaywall = false
    @State private var showReminderPrompt = false
    @State private var showReminderSetup = false

    private var profile: UserProfile? { profiles.first }
    private var plan: PersonalizedPlan? { plans.first }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bfPageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    lockedPlanCard
                }
                .padding(.horizontal, 22)
                .padding(.top, 48)
                .padding(.bottom, 152)
            }

            VStack(spacing: 12) {
                Button {
                    HapticManager.shared.mediumImpact()
                    AnalyticsTracker.capture("locked_unlock_cta_tapped")
                    showPaywall = true
                } label: {
                    Text("Unlock Body Fix")
                        .font(Typography.primaryCta)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.bfGradient))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
            .background(
                LinearGradient(
                    colors: [Color.bfPageBackground.opacity(0), Color.bfPageBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
                .allowsHitTesting(false)
            )
        }
        .onAppear {
            AnalyticsTracker.capture("locked_unlock_screen_shown")
            if showPaywallAfterOnboarding {
                showPaywallAfterOnboarding = false
                showPaywall = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheetView {
                showReminderPromptAfterSubscription = true
                showReminderPrompt = true
            } onDismissed: {}
        }
        .fullScreenCover(isPresented: $showReminderPrompt) {
            ReminderSoftPromptView {
                showReminderPrompt = false
                showReminderSetup = true
            } onNotNow: {
                showReminderPrompt = false
                showReminderPromptAfterSubscription = false
            }
        }
        .sheet(isPresented: $showReminderSetup) {
            ReminderSetupView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your plan is ready")
                .font(Typography.screenTitle)
                .foregroundStyle(Color.bfTextPrimary)

            Text("Unlock Body Fix to start your guided routine and keep your progress in one place.")
                .font(Typography.screenSubtitle)
                .foregroundStyle(Color.bfTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var lockedPlanCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(Color.bfHeroSurface))

                VStack(alignment: .leading, spacing: 5) {
                    Text(primaryArea)
                        .font(Typography.homeMeta)
                        .foregroundStyle(Color.bfBlue)

                    Text(durationLabel)
                        .font(Typography.homeCardTitleCompact)
                        .foregroundStyle(Color.bfTextPrimary)
                }
            }

            if let summary = plan?.summary, !summary.isEmpty {
                Text(summary)
                    .font(Typography.homeSupport)
                    .foregroundStyle(Color.bfTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                lockedBadge("Guided timers")
                lockedBadge("Streaks")
                lockedBadge("Reminders")
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.bfSurfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.bfBorder.opacity(0.58), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.035), radius: 12, y: 5)
    }

    private func lockedBadge(_ text: String) -> some View {
        Text(text)
            .font(Typography.metadataBadge)
            .foregroundStyle(Color.bfTextTertiary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.bfSurfaceMuted))
    }

    private var primaryArea: String {
        profile?.problemAreas.first ?? plan?.sourceProblemAreas.first ?? "Custom plan"
    }

    private var durationLabel: String {
        guard let seconds = plan?.targetDurationSeconds, seconds > 0 else { return "Your guided routine" }
        let minutes = max(1, seconds / 60)
        return "\(minutes)-minute first session"
    }
}
