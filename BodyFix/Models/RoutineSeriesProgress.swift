import Foundation
import SwiftData

@Model
final class RoutineSeriesProgress {
    var seriesId: String
    var completedLevel: Int
    var lastCompletedAt: Date?

    init(seriesId: String, completedLevel: Int = 0, lastCompletedAt: Date? = nil) {
        self.seriesId = seriesId
        self.completedLevel = completedLevel
        self.lastCompletedAt = lastCompletedAt
    }
}
