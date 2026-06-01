import SwiftUI

struct PaywallSheetView: View {
    let onSubscribed: () -> Void
    let onDismissed: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bfHeroSurface, Color.bfHeroSurfaceSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Spacer()
                    Button {
                        HapticManager.shared.softImpact()
                        PaywallManager.shared.markPaywallDismissed()
                        onDismissed()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.72))
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Unlock Body Fix")
                        .font(Typography.screenTitle)
                        .foregroundStyle(Color.bfHeroTextPrimary)

                    Text("Get full access to your guided plan, stretch timers, progress tracking, and saved routines.")
                        .font(Typography.screenSubtitle)
                        .foregroundStyle(Color.bfHeroTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    paywallBenefit("Personalized routine built from your answers")
                    paywallBenefit("Guided timers for every stretch")
                    paywallBenefit("Progress, streaks, and reminders")
                }
                .padding(.vertical, 4)

                Button {
                    PaywallManager.shared.markSubscriptionActive()
                    onSubscribed()
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(Typography.primaryCta)
                        .foregroundStyle(Color.bfHeroSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(hex: "#5EEAD4"))
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            PaywallManager.shared.showPaywall()
        }
    }

    private func paywallBenefit(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color(hex: "#5EEAD4"))
            Text(text)
                .font(Typography.homeSupport)
                .foregroundStyle(Color.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
