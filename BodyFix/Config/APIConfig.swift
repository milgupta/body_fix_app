import Foundation

enum APIConfig {
    /// Reads `ANTHROPIC_API_KEY` from `Config.plist` in the app bundle (add your key locally; do not commit secrets).
    static var anthropicAPIKey: String? {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let key = dict["ANTHROPIC_API_KEY"] as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        return key
    }
}
