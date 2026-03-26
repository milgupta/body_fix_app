import Foundation

struct StretchListRoute: Hashable {
    let muscles: Set<MuscleGroup>
}

struct StretchTimerRoute: Hashable {
    let stretchIds: [String]
    let startIndex: Int
}

struct SessionCompleteRoute: Hashable {
    let stretchNames: [String]
    let muscleGroupRaws: [String]
    let totalSeconds: Int
}
