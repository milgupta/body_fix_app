import Foundation

struct Stretch: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let muscleGroup: String
    let duration: Int
    let repScheme: String
    let description: String
    let difficulty: Int
    let imageName: String
    let position: String?
    let support: String?

    var muscle: MuscleGroup? {
        MuscleGroup(rawValue: muscleGroup)
    }

    /// Hold-based stretches use the circular second timer; rep-based use rep counter + pause/next rep.
    var isRepBased: Bool {
        let lower = repScheme.lowercased()
        if lower.contains("hold") { return false }
        return lower.range(of: #"\d+\s*(reps?|circles|rounds|swings|press-ups|pressups)"#, options: .regularExpression) != nil
    }

    /// Parsed target reps for rep-based mode (first number in `repScheme`, default 10).
    var targetReps: Int {
        guard isRepBased else { return 0 }
        let numbers = repScheme.matches(for: #"\d+"#).compactMap(Int.init)
        guard !numbers.isEmpty else { return 10 }

        let lower = repScheme.lowercased()
        var total: Int
        if numbers.count >= 2, lower.contains(" x ") {
            total = numbers[0] * numbers[1]
        } else {
            total = numbers[0]
        }

        if lower.contains("each side") || lower.contains("each arm") || lower.contains("each leg") {
            total *= 2
        }

        return max(1, total)
    }

    /// Badge label for list/timer ("45s" style or rep scheme).
    var durationBadgeText: String {
        if !repScheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return repScheme
        }
        return "\(duration)s"
    }
}

private extension String {
    func matches(for pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let matchRange = Range(match.range, in: self) else { return nil }
            return String(self[matchRange])
        }
    }
}
