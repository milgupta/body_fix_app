import Foundation

struct RoutineSeries: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let levelRoutineIds: [String]
    let difficultyLabel: String
    let relatedMuscleGroups: [String]
    let imageStretchIds: [String]?
}
