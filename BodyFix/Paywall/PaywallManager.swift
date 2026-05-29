import Foundation
import SuperwallKit

class PaywallManager {
    static let shared = PaywallManager()

    static let subscriptionKey = "bodyfix_subscription_active"
    static let paywallShownDateKey = "paywall_shown_date"
    static let showPaywallAfterOnboardingKey = "show_paywall_after_onboarding"
    static let onboardingMainPlacement = "paywall_main"
    static let onboardingDeclinePlacement = "paywall_decline"

    private init() {}

    private var isConfigured = false
    private var onboardingMainHandler: PaywallPresentationHandler?
    private var onboardingDeclineHandler: PaywallPresentationHandler?

    func configure() {
        guard !isConfigured, let apiKey = APIConfig.superwallAPIKey else { return }
        Superwall.configure(apiKey: apiKey)
        isConfigured = true
    }

    func showPaywall() {
        // When Superwall is integrated, register placement here.
        UserDefaults.standard.set(Date(), forKey: Self.paywallShownDateKey)
        AnalyticsTracker.capture("paywall_shown")
    }

    func presentOnboardingPaywalls(onComplete: @escaping () -> Void) {
        guard isConfigured else {
            onComplete()
            return
        }

        let mainHandler = PaywallPresentationHandler()
        onboardingMainHandler = mainHandler

        mainHandler.onPresent { _ in
            self.markPaywallShown(placement: Self.onboardingMainPlacement)
        }
        mainHandler.onDismiss { _, result in
            switch result {
            case .declined:
                self.presentOnboardingDeclinePaywall(onComplete: onComplete)
            case .purchased, .restored:
                self.markSubscriptionActive()
                self.clearOnboardingHandlers()
                onComplete()
            }
        }
        mainHandler.onSkip { _ in
            self.clearOnboardingHandlers()
            onComplete()
        }
        mainHandler.onError { _ in
            self.clearOnboardingHandlers()
            onComplete()
        }

        Superwall.shared.register(
            placement: Self.onboardingMainPlacement,
            params: ["source": "onboarding_trial_intro"],
            handler: mainHandler
        )
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

    private func presentOnboardingDeclinePaywall(onComplete: @escaping () -> Void) {
        let declineHandler = PaywallPresentationHandler()
        onboardingDeclineHandler = declineHandler

        declineHandler.onPresent { _ in
            self.markPaywallShown(placement: Self.onboardingDeclinePlacement)
        }
        declineHandler.onDismiss { _, result in
            if case .purchased = result {
                self.markSubscriptionActive()
            } else if case .restored = result {
                self.markSubscriptionActive()
            } else {
                self.markPaywallDismissed()
            }
            self.clearOnboardingHandlers()
            onComplete()
        }
        declineHandler.onSkip { _ in
            self.clearOnboardingHandlers()
            onComplete()
        }
        declineHandler.onError { _ in
            self.clearOnboardingHandlers()
            onComplete()
        }

        Superwall.shared.register(
            placement: Self.onboardingDeclinePlacement,
            params: ["source": "onboarding_trial_intro"],
            handler: declineHandler
        )
    }

    private func markPaywallShown(placement: String) {
        UserDefaults.standard.set(Date(), forKey: Self.paywallShownDateKey)
        AnalyticsTracker.capture("paywall_shown", properties: ["placement": placement])
    }

    private func clearOnboardingHandlers() {
        onboardingMainHandler = nil
        onboardingDeclineHandler = nil
    }
}
