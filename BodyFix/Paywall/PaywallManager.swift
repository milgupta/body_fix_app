import Foundation
import Observation
import SuperwallKit

@Observable
final class PaywallManager: SuperwallDelegate {
    static let shared = PaywallManager()

    static let paywallShownDateKey = "paywall_shown_date"
    static let onboardingMainPlacement = "paywall_main"
    static let onboardingDeclinePlacement = "paywall_decline"

    private init() {}

    private(set) var isSubscribed = false
    private var isConfigured = false
    private var onboardingMainHandler: PaywallPresentationHandler?
    private var onboardingDeclineHandler: PaywallPresentationHandler?
    private var lockedMainHandler: PaywallPresentationHandler?

    func configure() {
        guard !isConfigured, let apiKey = APIConfig.superwallAPIKey else { return }
        let options = SuperwallOptions()
        #if DEBUG
        options.shouldBypassAppTransactionCheck = true
        #endif
        Superwall.configure(apiKey: apiKey, options: options)
        Superwall.shared.delegate = self
        updateSubscriptionStatus(Superwall.shared.subscriptionStatus)
        isConfigured = true
    }

    func presentMainPaywall(source: String) {
        guard isConfigured else {
            HapticManager.shared.error()
            return
        }

        let handler = PaywallPresentationHandler()
        lockedMainHandler = handler
        handler.onPresent { _ in
            self.markPaywallShown(placement: Self.onboardingMainPlacement)
        }
        handler.onDismiss { _, result in
            if case .declined = result {
                AnalyticsTracker.capture("subscription_dismissed")
            }
            self.lockedMainHandler = nil
        }
        handler.onSkip { _ in
            self.lockedMainHandler = nil
        }
        handler.onError { _ in
            HapticManager.shared.error()
            self.lockedMainHandler = nil
        }

        Superwall.shared.register(
            placement: Self.onboardingMainPlacement,
            params: ["source": source],
            handler: handler
        )
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
                HapticManager.shared.success()
                self.clearOnboardingHandlers()
                onComplete()
            }
        }
        mainHandler.onSkip { _ in
            self.clearOnboardingHandlers()
            onComplete()
        }
        mainHandler.onError { _ in
            HapticManager.shared.error()
            self.clearOnboardingHandlers()
            onComplete()
        }

        Superwall.shared.register(
            placement: Self.onboardingMainPlacement,
            params: ["source": "onboarding_trial_intro"],
            handler: mainHandler
        )
    }

    var wasPaywallShownToday: Bool {
        guard let date = UserDefaults.standard.object(forKey: Self.paywallShownDateKey) as? Date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    func subscriptionStatusDidChange(from oldValue: SubscriptionStatus, to newValue: SubscriptionStatus) {
        updateSubscriptionStatus(newValue)
        guard oldValue.isActive != newValue.isActive else { return }
        AnalyticsTracker.capture(newValue.isActive ? "subscription_activated" : "subscription_deactivated")
    }

    private func presentOnboardingDeclinePaywall(onComplete: @escaping () -> Void) {
        let declineHandler = PaywallPresentationHandler()
        onboardingDeclineHandler = declineHandler

        declineHandler.onPresent { _ in
            self.markPaywallShown(placement: Self.onboardingDeclinePlacement)
        }
        declineHandler.onDismiss { _, result in
            if case .purchased = result {
                HapticManager.shared.success()
            } else if case .restored = result {
                HapticManager.shared.success()
            } else {
                AnalyticsTracker.capture("subscription_dismissed")
            }
            self.clearOnboardingHandlers()
            onComplete()
        }
        declineHandler.onSkip { _ in
            self.clearOnboardingHandlers()
            onComplete()
        }
        declineHandler.onError { _ in
            HapticManager.shared.error()
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

    private func updateSubscriptionStatus(_ status: SubscriptionStatus) {
        isSubscribed = status.isActive
    }
}
