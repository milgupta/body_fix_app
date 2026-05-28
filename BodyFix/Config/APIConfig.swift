import Foundation

enum APIConfig {
    /// Reads `ANTHROPIC_API_KEY` from `Config.plist` in the app bundle (add your key locally; do not commit secrets).
    static var anthropicAPIKey: String? {
        stringValue(for: "ANTHROPIC_API_KEY")
    }

    static var postHogProjectToken: String? {
        stringValue(for: "POSTHOG_PROJECT_TOKEN")
    }

    static var postHogHost: String? {
        stringValue(for: "POSTHOG_HOST")
    }

    private static func stringValue(for key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = dict[key] as? String
        else { return nil }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
