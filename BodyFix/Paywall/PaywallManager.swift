import Foundation

class PaywallManager {
    static let shared = PaywallManager()

    static let subscriptionKey = "bodyfix_subscription_active"
    static let paywallShownDateKey = "paywall_shown_date"
    static let showPaywallAfterOnboardingKey = "show_paywall_after_onboarding"

    private init() {}

    func configure() {
        // Superwall SDK initialization when integrated
    }

    func showPaywall() {
        // When Superwall is integrated, register placement here.
        UserDefaults.standard.set(Date(), forKey: Self.paywallShownDateKey)
        AnalyticsTracker.capture("paywall_shown")
    }

    func markSubscriptionActive() {
        UserDefaults.standard.set(true, forKey: Self.subscriptionKey)
        UserDefaults.standard.set(false, forKey: Self.showPaywallAfterOnboardingKey)
        AnalyticsTracker.capture("subscription_activated")
    }

    func markPaywallDismissed() {
        UserDefaults.standard.set(false, forKey: Self.showPaywallAfterOnboardingKey)
        AnalyticsTracker.capture("subscription_dismissed")
    }

    func requestPaywallAfterOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.showPaywallAfterOnboardingKey)
    }

    func showExitOffer() {}

    var isSubscribed: Bool {
        UserDefaults.standard.bool(forKey: Self.subscriptionKey)
    }

    var wasPaywallShownToday: Bool {
        guard let date = UserDefaults.standard.object(forKey: Self.paywallShownDateKey) as? Date else { return false }
        return Calendar.current.isDateInToday(date)
    }
}
