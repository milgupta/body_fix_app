import Foundation

struct StretchListRoute: Hashable {
    let muscles: Set<MuscleGroup>
    var perGroup: Int? = 3
    var title: String? = nil
}

struct MusclePickerRoute: Hashable {}

struct RoutineStretchListRoute: Hashable {
    let routineId: String
}

struct SeriesDetailRoute: Hashable {
    let seriesId: String
}

struct StretchTimerRoute: Hashable {
    let stretchIds: [String]
    let startIndex: Int
    var routineName: String? = nil
    var seriesId: String? = nil
    var seriesLevel: Int? = nil
    var durationOverrides: [String: Int] = [:]
    var repOverrides: [String: Int] = [:]
}

struct SessionCompleteRoute: Hashable {
    let stretchNames: [String]
    let muscleGroupRaws: [String]
    let totalSeconds: Int
    var routineName: String? = nil
    var seriesId: String? = nil
    var seriesLevel: Int? = nil
}

struct PersonalizedPlanRoute: Hashable {}

struct PersonalizedPlanEditorRoute: Hashable {}

struct SavedPlanDetailRoute: Hashable {
    let savedRoutineId: UUID
}
