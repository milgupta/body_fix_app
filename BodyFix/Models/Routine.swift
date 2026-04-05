import Foundation

enum RoutineCategory: String, Codable, Hashable {
    case featured
    case quick
    case injury
    case activity
    case recommendedCandidate
    case seriesLevel
}

struct Routine: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let categories: [RoutineCategory]
    let stretchIds: [String]
    let relatedMuscleGroups: [String]
    let tags: [String]
    let durationMinutes: Int
    let imageStretchIds: [String]?
    let seriesId: String?
    let level: Int?

    var durationLabel: String {
        durationMinutes == 1 ? "1 MINUTE" : "\(durationMinutes) MINUTES"
    }

    var shortDurationLabel: String {
        durationMinutes == 1 ? "1 MIN" : "\(durationMinutes) MIN"
    }

    var thumbnailStretchIds: [String] {
        let ids = imageStretchIds ?? stretchIds
        return ids.isEmpty ? stretchIds : ids
    }

    func hasCategory(_ category: RoutineCategory) -> Bool {
        categories.contains(category)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case categories
        case stretchIds
        case relatedMuscleGroups
        case tags
        case durationMinutes
        case imageStretchIds
        case seriesId
        case level
    }

    init(
        id: String,
        name: String,
        categories: [RoutineCategory],
        stretchIds: [String],
        relatedMuscleGroups: [String],
        tags: [String],
        durationMinutes: Int,
        imageStretchIds: [String]? = nil,
        seriesId: String? = nil,
        level: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.categories = categories
        self.stretchIds = stretchIds
        self.relatedMuscleGroups = relatedMuscleGroups
        self.tags = tags
        self.durationMinutes = durationMinutes
        self.imageStretchIds = imageStretchIds
        self.seriesId = seriesId
        self.level = level
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        categories = try container.decode([RoutineCategory].self, forKey: .categories)
        stretchIds = try container.decode([String].self, forKey: .stretchIds)
        relatedMuscleGroups = try container.decode([String].self, forKey: .relatedMuscleGroups)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
            ?? max(1, Int(ceil(Double(stretchIds.count) * 0.5)))
        imageStretchIds = try container.decodeIfPresent([String].self, forKey: .imageStretchIds)
        seriesId = try container.decodeIfPresent(String.self, forKey: .seriesId)
        level = try container.decodeIfPresent(Int.self, forKey: .level)
    }
}

enum SearchResult: Hashable {
    case routine(Routine)
    case stretch(Stretch)
}
