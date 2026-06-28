import SwiftUI
import SwiftData

private enum SettingsExternalLinks {
    static let supportEmail = "hello@getbodyfix.com"
    static let privacyURL = URL(string: "https://getbodyfix.com/privacy.html")!
    static let termsURL = URL(string: "https://getbodyfix.com/terms.html")!
    static let citationsURL = URL(string: "https://getbodyfix.com/citations.html")!
    static let manageSubscriptionsURL = URL(string: "itms-apps://apps.apple.com/account/subscriptions")!
    /// Swap for your App Store product page when available.
    static let appShareURL = URL(string: "https://getbodyfix.com/")!
}

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage(HapticManager.enabledKey) private var hapticsEnabled = true
    @Query private var profiles: [UserProfile]
    @State private var paywallManager = PaywallManager.shared
    @State private var showReminderSetup = false
    @State private var browserDestination: InAppBrowserDestination?
    @State private var showNameEditor = false

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(v) (\(b))"
    }

    private var profile: UserProfile? {
        profiles.first
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.top, 20)
                            .padding(.bottom, 36)

                        sectionTitle("Profile")
                        VStack(spacing: 10) {
                            nameRow
                        }
                        .padding(.bottom, 28)

                        sectionTitle("Notifications")
                        VStack(spacing: 10) {
                            notificationsRow
                        }
                        .padding(.bottom, 28)

                        sectionTitle("Experience")
                        VStack(spacing: 10) {
                            hapticsRow
                        }
                        .padding(.bottom, 28)

                        sectionTitle("Membership")
                        VStack(spacing: 10) {
                            settingsButton(
                                title: "Manage Subscription",
                                systemImage: "creditcard.fill"
                            ) {
                                openURL(SettingsExternalLinks.manageSubscriptionsURL)
                            }
                        }
                        .padding(.bottom, 28)

                        sectionTitle("Support")
                        VStack(spacing: 10) {
                            settingsButton(
                                title: "Contact Us",
                                systemImage: "envelope.fill"
                            ) {
                                openMail(subject: "Body Fix support")
                            }

                            shareRow

                            settingsButton(
                                title: "Feature Request & Feedback",
                                systemImage: "lightbulb.fill"
                            ) {
                                openMail(subject: "Body Fix feedback")
                            }
                        }
                        .padding(.bottom, 28)

                        sectionTitle("Legal")
                        VStack(spacing: 10) {
                            settingsButton(
                                title: "Health Information & Citations",
                                systemImage: "book.pages.fill"
                            ) {
                                openInAppBrowser(SettingsExternalLinks.citationsURL)
                            }

                            settingsButton(
                                title: "Terms Of Use",
                                systemImage: "doc.text.fill"
                            ) {
                                openInAppBrowser(SettingsExternalLinks.termsURL)
                            }

                            settingsButton(
                                title: "Privacy Policy",
                                systemImage: "lock.shield.fill"
                            ) {
                                openInAppBrowser(SettingsExternalLinks.privacyURL)
                            }
                        }
                        .padding(.bottom, 28)

                        sectionTitle("About")
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
            .sheet(item: $browserDestination) { destination in
                InAppBrowserView(url: destination.url)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showNameEditor) {
                if let profile {
                    NameEditorView(profile: profile)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(Typography.screenTitle)
                .foregroundStyle(Color.bfTextPrimary)
            Text("Preferences & Support")
                .font(Typography.screenSubtitle)
                .foregroundStyle(Color.bfTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.bfTextMuted)
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
            rowContent(title: "Share Body Fix", systemImage: "square.and.arrow.up", showsChevron: true)
        }
        .simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.lightImpact()
        })
    }

    private var nameRow: some View {
        Button {
            HapticManager.shared.lightImpact()
            showNameEditor = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.bfMint)
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Name")
                        .font(Typography.controlLabel)
                        .foregroundStyle(Color.bfTextPrimary)

                    Text(profileNameSummary)
                        .font(Typography.caption)
                        .foregroundStyle(Color.bfTextTertiary)
                }

                Spacer(minLength: 8)

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
        .disabled(profile == nil)
        .opacity(profile == nil ? 0.55 : 1)
    }

    private var profileNameSummary: String {
        let trimmed = profile?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Add Your Name" : trimmed
    }

    private var notificationsRow: some View {
        Button {
            if paywallManager.isSubscribed {
                HapticManager.shared.lightImpact()
                AnalyticsTracker.capture("notification_setup_started", properties: ["source": "settings"])
                showReminderSetup = true
            } else {
                HapticManager.shared.mediumImpact()
                AnalyticsTracker.capture("notification_locked_row_tapped")
                paywallManager.presentMainPaywall(source: "settings_reminders")
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: paywallManager.isSubscribed ? "bell.fill" : "lock.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.bfMint)
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Stretch Reminders")
                        .font(Typography.controlLabel)
                        .foregroundStyle(Color.bfTextPrimary)

                    Text(paywallManager.isSubscribed ? reminderSummary : "Unlock To Set Reminders")
                        .font(Typography.caption)
                        .foregroundStyle(Color.bfTextTertiary)
                }

                Spacer(minLength: 8)

                if !paywallManager.isSubscribed {
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

    private var hapticsRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "waveform")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.bfMint)
                .frame(width: 28, alignment: .center)

            Text("Haptics")
                .font(Typography.controlLabel)
                .foregroundStyle(Color.bfTextPrimary)

            Spacer(minLength: 8)

            Toggle("Haptics", isOn: $hapticsEnabled)
                .labelsHidden()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
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

    private var reminderSummary: String {
        let preferences = ReminderStore.preferences
        guard preferences.hasCompleteSchedule else { return "Choose Days And Time" }
        return "\(daySummary(preferences.days)) At \(timeSummary(hour: preferences.hour, minute: preferences.minute))"
    }

    private func daySummary(_ days: Set<Int>) -> String {
        let labels = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]
        return days.sorted().compactMap { labels[$0] }.joined(separator: " ")
    }

    private func timeSummary(hour: Int?, minute: Int?) -> String {
        guard let hour, let minute else { return "Choose Time" }
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
            Text("Version")
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

    private func openInAppBrowser(_ url: URL) {
        browserDestination = InAppBrowserDestination(url: url)
    }

}

private struct NameEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let profile: UserProfile

    @State private var name: String

    init(profile: UserProfile) {
        self.profile = profile
        _name = State(initialValue: profile.name)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Name")
                    .font(Typography.navTitle)
                    .foregroundStyle(Color.bfTextPrimary)

                TextField("Your Name", text: $name)
                    .font(Typography.controlLabel)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.bfSurfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.bfBorder.opacity(0.56), lineWidth: 1)
                    )
                    .onSubmit(save)

                Spacer()
            }
            .padding(24)
            .background(Color.bfBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        profile.name = trimmedName
        try? modelContext.save()
        HapticManager.shared.success()
        dismiss()
    }
}

#Preview {
    SettingsView()
}
