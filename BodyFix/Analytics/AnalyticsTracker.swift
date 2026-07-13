import Foundation

#if canImport(PostHog)
import PostHog
#endif

#if canImport(FacebookCore)
import FacebookCore
#endif

enum AnalyticsTracker {
    private static var isConfigured = false

    static func configure() {
        guard !isConfigured, let token = APIConfig.postHogProjectToken else { return }
        isConfigured = true

        #if canImport(PostHog)
        let config: PostHogConfig
        if let host = APIConfig.postHogHost {
            config = PostHogConfig(projectToken: token, host: host)
        } else {
            config = PostHogConfig(projectToken: token)
        }
        PostHogSDK.shared.setup(config)
        #endif
    }

    static func capture(_ event: String, properties: [String: Any] = [:]) {
        #if canImport(PostHog)
        if isConfigured {
            PostHogSDK.shared.capture(event, properties: properties)
        }
        #endif

        #if canImport(FacebookCore)
        let metaParameters = Dictionary(
            uniqueKeysWithValues: properties.map {
                (AppEvents.ParameterName($0.key), $0.value)
            }
        )
        AppEvents.shared.logEvent(AppEvents.Name(event), parameters: metaParameters)
        #else
        _ = event
        _ = properties
        #endif
    }
}

enum AnalyticsEvent {
    static let onboardingStarted = "onboarding_started"
    static let onboardingStepCompleted = "onboarding_step_completed"
    static let onboardingBackTapped = "onboarding_back_tapped"
    static let onboardingBackgrounded = "onboarding_backgrounded"
    static let onboardingResumed = "onboarding_resumed"
    static let onboardingAgeRangeSelected = "onboarding_age_range_selected"
    static let onboardingPainProfileSubmitted = "onboarding_pain_profile_submitted"
    static let onboardingProblemAreaSelected = "onboarding_problem_area_selected"
    static let onboardingCompleted = "onboarding_completed"

    static let routineStarted = "routine_started"
    static let routineCompleted = "routine_completed"
    static let routineAbandoned = "routine_abandoned"
    static let stretchViewed = "stretch_viewed"
    static let stretchStarted = "stretch_started"
    static let stretchCompleted = "stretch_completed"
    static let stretchInfoOpened = "stretch_info_opened"

    static let notificationPermissionRequested = "notification_permission_requested"
    static let notificationSetupViewed = "notification_setup_viewed"

    static func onboardingStepViewed(stepIndex: Int, stepID: String) -> String {
        let stepNumber = stepIndex + 1
        return "onboarding_\(String(format: "%02d", stepNumber))_\(stepID)_viewed"
    }
}
