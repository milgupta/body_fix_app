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

    var muscle: MuscleGroup? {
        MuscleGroup(rawValue: muscleGroup)
    }

    /// Hold-based stretches use the circular second timer; rep-based use rep counter + pause/next rep.
    var isRepBased: Bool {
        let lower = repScheme.lowercased()
        if lower.contains("hold") { return false }
        return lower.range(of: #"\d+\s*(reps?|circles|rounds)"#, options: .regularExpression) != nil
    }

    /// Parsed target reps for rep-based mode (first number in `repScheme`, default 10).
    var targetReps: Int {
        guard isRepBased else { return 0 }
        if let range = repScheme.range(of: #"\d+"#, options: .regularExpression) {
            return Int(repScheme[range]) ?? 10
        }
        return 10
    }

    /// Badge label for list/timer ("45s" style or rep scheme).
    var durationBadgeText: String {
        if isRepBased {
            return repScheme
        }
        return "\(duration)s"
    }
}
