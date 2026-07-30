import Foundation
import AppstackSDK

enum AppstackTracker {
    private(set) static var isConfigured = false

    static func configure() {
        guard !isConfigured, let apiKey = APIConfig.appstackAPIKey else { return }
        isConfigured = true

        AppstackAttributionSdk.shared.configure(
            apiKey: apiKey,
            logLevel: .info
        )
    }

    static func capture(_ event: String, properties: [String: Any]) {
        guard isConfigured else { return }

        switch event {
        case AnalyticsEvent.onboardingCompleted:
            AppstackAttributionSdk.shared.sendEvent(event: .TUTORIAL_COMPLETE)

        case AnalyticsEvent.routineStarted:
            AppstackAttributionSdk.shared.sendEvent(
                event: .CUSTOM,
                name: AnalyticsEvent.routineStarted
            )

        case AnalyticsEvent.routineCompleted:
            AppstackAttributionSdk.shared.sendEvent(
                event: .CUSTOM,
                name: AnalyticsEvent.routineCompleted,
                parameters: routineCompletionParameters(from: properties)
            )

        case "paywall_shown":
            AppstackAttributionSdk.shared.sendEvent(
                event: .VIEW_CONTENT,
                parameters: ["content_type": "paywall"]
            )

        default:
            break
        }
    }

    private static func routineCompletionParameters(
        from properties: [String: Any]
    ) -> [String: Any] {
        var parameters: [String: Any] = [:]
        if let elapsedSeconds = properties["elapsed_seconds"] {
            parameters["elapsed_seconds"] = elapsedSeconds
        }
        if let completedStretchCount = properties["completed_stretch_count"] {
            parameters["completed_stretch_count"] = completedStretchCount
        }
        return parameters
    }
}
