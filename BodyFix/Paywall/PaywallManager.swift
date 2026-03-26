import Foundation

class PaywallManager {
    static let shared = PaywallManager()

    private let subscriptionKey = "bodyfix_subscription_active"

    private init() {}

    func configure() {
        // Superwall SDK initialization when integrated
    }

    func showPaywall() {
        // When Superwall is integrated, register placement here.
        UserDefaults.standard.set(true, forKey: subscriptionKey)
    }

    func showExitOffer() {}

    var isSubscribed: Bool {
        UserDefaults.standard.bool(forKey: subscriptionKey)
    }
}
