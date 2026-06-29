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

enum StretchTimerContext: Hashable {
    case standard
    case onboardingPreview
}

enum StretchTimerSource: String, Hashable {
    case presetRoutine = "preset_routine"
    case personalizedPlan = "personalized_plan"
    case savedPlan = "saved_plan"
    case browseArea = "browse_area"
    case search = "search"
    case onboardingPreview = "onboarding_preview"
    case unknown
}

struct StretchTimerRoute: Hashable {
    let stretchIds: [String]
    let startIndex: Int
    var routineId: String? = nil
    var routineName: String? = nil
    var seriesId: String? = nil
    var seriesLevel: Int? = nil
    var durationOverrides: [String: Int] = [:]
    var repOverrides: [String: Int] = [:]
    var showsStartCountdown: Bool = false
    var context: StretchTimerContext = .standard
    var source: StretchTimerSource = .unknown
}

struct SessionCompleteRoute: Hashable {
    let stretchNames: [String]
    let muscleGroupRaws: [String]
    let totalSeconds: Int
    var routineId: String? = nil
    var routineName: String? = nil
    var seriesId: String? = nil
    var seriesLevel: Int? = nil
    var source: StretchTimerSource = .unknown
}

struct PersonalizedPlanRoute: Hashable {}

struct PersonalizedPlanEditorRoute: Hashable {}

struct SavedPlanDetailRoute: Hashable {
    let savedRoutineId: UUID
}
