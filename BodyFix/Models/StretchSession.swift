import Foundation
import SwiftData

@Model
final class StretchSession {
    var id: UUID
    var date: Date
    var muscleGroups: [String]
    var stretchNames: [String]
    var totalDuration: Int
    var stretchCount: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        muscleGroups: [String] = [],
        stretchNames: [String] = [],
        totalDuration: Int = 0,
        stretchCount: Int = 0
    ) {
        self.id = id
        self.date = date
        self.muscleGroups = muscleGroups
        self.stretchNames = stretchNames
        self.totalDuration = totalDuration
        self.stretchCount = stretchCount
    }
}
