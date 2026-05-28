import Foundation

enum RatingTrigger: String {
    case onboardingPlan
    case firstPaidSession
    case fiveSessions
    case sevenDayStreak
    case completedSeries
}

enum RatingManager {
    private static let onboardingAttemptedKey = "rating_onboarding_attempted"
    private static let hasRequestedReviewKey = "has_rated"
    private static let firstPaidSessionKey = "rating_trigger_first_paid_session"
    private static let fiveSessionsKey = "rating_trigger_sessions"
    private static let sevenDayStreakKey = "rating_trigger_streak"
    private static let completedSeriesKey = "rating_trigger_series"

    static func canRequestOnboardingRating() -> Bool {
        !UserDefaults.standard.bool(forKey: onboardingAttemptedKey)
    }

    static func markReviewRequested(trigger: RatingTrigger) {
        if trigger == .onboardingPlan {
            UserDefaults.standard.set(true, forKey: onboardingAttemptedKey)
        }
        UserDefaults.standard.set(true, forKey: hasRequestedReviewKey)
        AnalyticsTracker.capture("app_store_rating_requested", properties: ["trigger": trigger.rawValue])
    }

    static func eligibleMilestoneTrigger(
        isSubscribed: Bool,
        completedSessionCount: Int,
        currentStreak: Int,
        completedSeries: Bool
    ) -> RatingTrigger? {
        guard isSubscribed,
              !UserDefaults.standard.bool(forKey: hasRequestedReviewKey),
              !PaywallManager.shared.wasPaywallShownToday
        else { return nil }

        let defaults = UserDefaults.standard
        if completedSessionCount >= 1 && !defaults.bool(forKey: firstPaidSessionKey) {
            defaults.set(true, forKey: firstPaidSessionKey)
            return .firstPaidSession
        }
        if completedSessionCount >= 5 && !defaults.bool(forKey: fiveSessionsKey) {
            defaults.set(true, forKey: fiveSessionsKey)
            return .fiveSessions
        }
        if currentStreak >= 7 && !defaults.bool(forKey: sevenDayStreakKey) {
            defaults.set(true, forKey: sevenDayStreakKey)
            return .sevenDayStreak
        }
        if completedSeries && !defaults.bool(forKey: completedSeriesKey) {
            defaults.set(true, forKey: completedSeriesKey)
            return .completedSeries
        }

        return nil
    }
}
