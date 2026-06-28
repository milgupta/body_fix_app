import Foundation

struct Stretch: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let muscleGroup: String
    let muscleGroups: [String]
    let duration: Int
    let repScheme: String
    let description: String
    let difficulty: Int
    let imageName: String
    let position: String?
    let support: String?

    init(
        id: String,
        name: String,
        muscleGroup: String,
        muscleGroups: [String]? = nil,
        duration: Int,
        repScheme: String,
        description: String,
        difficulty: Int,
        imageName: String,
        position: String? = nil,
        support: String? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.muscleGroups = Self.normalizedMuscleGroups(primary: muscleGroup, groups: muscleGroups)
        self.duration = duration
        self.repScheme = repScheme
        self.description = description
        self.difficulty = difficulty
        self.imageName = imageName
        self.position = position
        self.support = support
    }

    var muscle: MuscleGroup? {
        MuscleGroup(rawValue: muscleGroup)
    }

    var muscles: [MuscleGroup] {
        muscleGroups.compactMap(MuscleGroup.init(rawValue:))
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

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case muscleGroup
        case muscleGroups
        case duration
        case repScheme
        case description
        case difficulty
        case imageName
        case position
        case support
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let muscleGroup = try container.decode(String.self, forKey: .muscleGroup)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            name: try container.decode(String.self, forKey: .name),
            muscleGroup: muscleGroup,
            muscleGroups: try container.decodeIfPresent([String].self, forKey: .muscleGroups),
            duration: try container.decode(Int.self, forKey: .duration),
            repScheme: try container.decode(String.self, forKey: .repScheme),
            description: try container.decode(String.self, forKey: .description),
            difficulty: try container.decode(Int.self, forKey: .difficulty),
            imageName: try container.decode(String.self, forKey: .imageName),
            position: try container.decodeIfPresent(String.self, forKey: .position),
            support: try container.decodeIfPresent(String.self, forKey: .support)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(muscleGroup, forKey: .muscleGroup)
        try container.encode(muscleGroups, forKey: .muscleGroups)
        try container.encode(duration, forKey: .duration)
        try container.encode(repScheme, forKey: .repScheme)
        try container.encode(description, forKey: .description)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(imageName, forKey: .imageName)
        try container.encodeIfPresent(position, forKey: .position)
        try container.encodeIfPresent(support, forKey: .support)
    }

    private static func normalizedMuscleGroups(primary: String, groups: [String]?) -> [String] {
        var normalized: [String] = []
        for group in [primary] + (groups ?? []) where !normalized.contains(group) {
            normalized.append(group)
        }
        return normalized
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
