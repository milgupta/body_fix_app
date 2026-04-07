import Foundation
import SwiftData

@Model
final class PersonalizedPlan {
    var routineId: String
    var stretchIds: [String]
    var targetDurationSeconds: Int
    var createdAt: Date
    var updatedAt: Date
    var sourceGoals: [String]
    var sourceProblemAreas: [String]
    var sourceDailyTime: String
    var sourceLifestyle: String
    var rationale: String
    var summary: String

    init(
        routineId: String,
        stretchIds: [String] = [],
        targetDurationSeconds: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        sourceGoals: [String] = [],
        sourceProblemAreas: [String] = [],
        sourceDailyTime: String = "",
        sourceLifestyle: String = "",
        rationale: String = "",
        summary: String = ""
    ) {
        self.routineId = routineId
        self.stretchIds = stretchIds
        self.targetDurationSeconds = targetDurationSeconds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceGoals = sourceGoals
        self.sourceProblemAreas = sourceProblemAreas
        self.sourceDailyTime = sourceDailyTime
        self.sourceLifestyle = sourceLifestyle
        self.rationale = rationale
        self.summary = summary
    }
}
