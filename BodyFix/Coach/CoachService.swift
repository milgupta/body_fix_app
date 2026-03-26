import Foundation

enum CoachServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Couldn't connect. Check your internet and try again."
        case .invalidResponse:
            return "Couldn't connect. Check your internet and try again."
        case .httpStatus:
            return "Couldn't connect. Check your internet and try again."
        }
    }
}

final class CoachService: @unchecked Sendable {
    static let shared = CoachService()

    private let url = URL(string: "https://api.anthropic.com/v1/messages")!

    private init() {}

    func send(
        userText: String,
        history: [CoachChatMessage],
        profile: UserProfile,
        recentSessions: [StretchSession]
    ) async throws -> String {
        guard let key = APIConfig.anthropicAPIKey else {
            throw CoachServiceError.missingAPIKey
        }

        let system = Self.buildSystemPrompt(profile: profile, recentSessions: recentSessions)
        var messages: [[String: String]] = []
        for m in history where !m.text.isEmpty {
            messages.append([
                "role": m.isUser ? "user" : "assistant",
                "content": m.text
            ])
        }
        messages.append(["role": "user", "content": userText])

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "system": system,
            "messages": messages
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CoachServiceError.invalidResponse
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw CoachServiceError.httpStatus(http.statusCode)
        }

        return try Self.parseAssistantText(from: data)
    }

    private static func parseAssistantText(from data: Data) throws -> String {
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = obj["content"] as? [[String: Any]]
        else {
            throw CoachServiceError.invalidResponse
        }
        let texts = content.compactMap { block -> String? in
            guard (block["type"] as? String) == "text" else { return nil }
            return block["text"] as? String
        }
        let joined = texts.joined(separator: "\n")
        guard !joined.isEmpty else { throw CoachServiceError.invalidResponse }
        return joined
    }

    private static func buildSystemPrompt(profile: UserProfile, recentSessions: [StretchSession]) -> String {
        let recent = recentSessions.prefix(5).map { session in
            let names = session.stretchNames.joined(separator: ", ")
            let df = ISO8601DateFormatter()
            return "- \(df.string(from: session.date)): \(names)"
        }.joined(separator: "\n")

        let problem = profile.problemAreas.joined(separator: ", ")
        let sitting = profile.lifestyle.isEmpty ? "not specified" : profile.lifestyle

        return """
        You are an AI stretching and mobility coach inside the Body Fix app. You help users with:
        - Stretching advice and technique tips
        - Understanding why certain muscles are tight
        - Pre/post workout stretching recommendations
        - Pain and discomfort guidance (always recommend seeing a doctor for persistent pain)
        - Recovery and mobility tips
        - Posture improvement advice

        Keep responses concise (2-4 sentences). Be warm, encouraging, and knowledgeable.
        Never provide medical diagnoses. Always recommend consulting a healthcare professional for persistent pain.

        User profile context:
        - Name: \(profile.name.isEmpty ? "User" : profile.name)
        - Activity level: \(profile.activityLevel)
        - Primary goal: \(profile.longTermGoal)
        - Problem areas: \(problem)
        - Sitting / lifestyle: \(sitting)
        - Experience / frequency: \(profile.stretchingFrequency)
        - Recent stretches:
        \(recent.isEmpty ? "- None logged yet" : recent)
        """
    }
}
