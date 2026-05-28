import SwiftUI
import SwiftData

/// Replace with your real URLs and support email before release.
private enum SettingsExternalLinks {
    static let supportEmail = "support@bodyfix.app"
    static let privacyURL = URL(string: "https://www.apple.com/legal/privacy/")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/terms/site.html")!
    static let manageSubscriptionsURL = URL(string: "itms-apps://apps.apple.com/account/subscriptions")!
    /// Swap for your App Store product page when available.
    static let appShareURL = URL(string: "https://apps.apple.com")!
}

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var plans: [PersonalizedPlan]
    @AppStorage(PaywallManager.subscriptionKey) private var isSubscribed = false
    @State private var showReminderSetup = false
    @State private var showPaywall = false

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.top, 20)
                            .padding(.bottom, 36)

                        sectionTitle("notifications")
                        VStack(spacing: 10) {
                            notificationsRow
                        }
                        .padding(.bottom, 28)

                        sectionTitle("membership")
                        VStack(spacing: 10) {
                            settingsButton(
                                title: "manage subscription",
                                systemImage: "creditcard.fill"
                            ) {
                                openURL(SettingsExternalLinks.manageSubscriptionsURL)
                            }
                        }
                        .padding(.bottom, 28)

                        sectionTitle("support")
                        VStack(spacing: 10) {
                            settingsButton(
                                title: "contact us",
                                systemImage: "envelope.fill"
                            ) {
                                openMail(subject: "Body Fix support")
                            }

                            shareRow

                            settingsButton(
                                title: "feature request & feedback",
                                systemImage: "lightbulb.fill"
                            ) {
                                openMail(subject: "Body Fix feedback")
                            }
                        }
                        .padding(.bottom, 28)

                        sectionTitle("legal")
                        VStack(spacing: 10) {
                            settingsButton(
                                title: "terms of use",
                                systemImage: "doc.text.fill"
                            ) {
                                openURL(SettingsExternalLinks.termsURL)
                            }

                            settingsButton(
                                title: "privacy policy",
                                systemImage: "lock.shield.fill"
                            ) {
                                openURL(SettingsExternalLinks.privacyURL)
                            }
                        }
                        .padding(.bottom, 28)

                        #if DEBUG
                        sectionTitle("developer")
                        VStack(spacing: 10) {
                            settingsButton(
                                title: "reset onboarding (debug)",
                                systemImage: "arrow.counterclockwise.circle.fill"
                            ) {
                                resetOnboardingForTesting()
                            }
                        }
                        .padding(.bottom, 28)
                        #endif

                        sectionTitle("about")
                        versionCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 112, 148))
                }
            }
            .background(Color.bfBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showReminderSetup) {
                ReminderSetupView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallSheetView {} onDismissed: {}
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("settings")
                .font(Typography.screenTitle)
                .foregroundStyle(Color.bfTextPrimary)
            Text("preferences & support")
                .font(Typography.screenSubtitle)
                .foregroundStyle(Color.bfTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(Typography.metadataBadge)
            .foregroundStyle(Color.bfTextMuted)
            .textCase(.lowercase)
            .padding(.bottom, 10)
    }

    private func settingsButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticManager.shared.lightImpact()
            action()
        } label: {
            rowContent(title: title, systemImage: systemImage, showsChevron: true)
        }
        .buttonStyle(.plain)
    }

    private var shareRow: some View {
        ShareLink(
            item: SettingsExternalLinks.appShareURL,
            subject: Text("Body Fix"),
            message: Text("Stretch and recover with Body Fix — guided mobility routines in one app."),
            preview: SharePreview("Body Fix", icon: Image(systemName: "figure.flexibility"))
        ) {
            rowContent(title: "share body fix", systemImage: "square.and.arrow.up", showsChevron: true)
        }
    }

    private var notificationsRow: some View {
        Button {
            HapticManager.shared.lightImpact()
            if isSubscribed {
                AnalyticsTracker.capture("notification_setup_started", properties: ["source": "settings"])
                showReminderSetup = true
            } else {
                AnalyticsTracker.capture("notification_locked_row_tapped")
                showPaywall = true
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSubscribed ? "bell.fill" : "lock.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.bfMint)
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: 5) {
                    Text("stretch reminders")
                        .font(Typography.controlLabel)
                        .foregroundStyle(Color.bfTextPrimary)

                    Text(isSubscribed ? reminderSummary : "unlock to set reminders")
                        .font(Typography.caption)
                        .foregroundStyle(Color.bfTextTertiary)
                }

                Spacer(minLength: 8)

                if !isSubscribed {
                    Text("PRO")
                        .font(Typography.metadataBadge)
                        .foregroundStyle(Color.bfHeroSurface)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: "#5EEAD4")))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.bfTextMuted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.bfSurfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.bfBorder.opacity(0.46), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var reminderSummary: String {
        let preferences = ReminderStore.preferences
        guard preferences.hasCompleteSchedule else { return "choose days and time" }
        return "\(daySummary(preferences.days)) at \(timeSummary(hour: preferences.hour, minute: preferences.minute))"
    }

    private func daySummary(_ days: Set<Int>) -> String {
        let labels = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]
        return days.sorted().compactMap { labels[$0] }.joined(separator: " ")
    }

    private func timeSummary(hour: Int?, minute: Int?) -> String {
        guard let hour, let minute else { return "Choose time" }
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func rowContent(title: String, systemImage: String, showsChevron: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.bfMint)
                .frame(width: 28, alignment: .center)
            Text(title)
                .font(Typography.controlLabel)
                .foregroundStyle(Color.bfTextPrimary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.bfTextMuted)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.46), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 3)
    }

    private var versionCard: some View {
        HStack {
            Text("version")
                .font(Typography.controlLabel)
                .foregroundStyle(Color.bfTextPrimary)
            Spacer()
            Text(appVersionString)
                .font(Typography.caption)
                .foregroundStyle(Color.bfTextTertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.46), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 3)
    }

    private func openMail(subject: String) {
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "mailto:\(SettingsExternalLinks.supportEmail)?subject=\(encoded)") else { return }
        openURL(url)
    }

    #if DEBUG
    private func resetOnboardingForTesting() {
        for profile in profiles {
            modelContext.delete(profile)
        }
        for plan in plans {
            modelContext.delete(plan)
        }
        UserDefaults.standard.set(false, forKey: PaywallManager.subscriptionKey)
        try? modelContext.save()
    }
    #endif
}

#Preview {
    SettingsView()
}
