import Foundation

#if canImport(PostHog)
import PostHog
#endif

enum AnalyticsTracker {
    private static var isConfigured = false

    static func configure() {
        guard !isConfigured, let token = APIConfig.postHogProjectToken else { return }
        isConfigured = true

        #if canImport(PostHog)
        let config: PostHogConfig
        if let host = APIConfig.postHogHost {
            config = PostHogConfig(apiKey: token, host: host)
        } else {
            config = PostHogConfig(apiKey: token)
        }
        PostHogSDK.shared.setup(config)
        #endif
    }

    static func capture(_ event: String, properties: [String: Any] = [:]) {
        #if canImport(PostHog)
        guard isConfigured else { return }
        PostHogSDK.shared.capture(event, properties: properties)
        #else
        _ = event
        _ = properties
        #endif
    }
}
