import Foundation
import SwiftData

@Model
final class StretchSession {
    var id: UUID
    var date: Date
    var stretchName: String
    var bodyRegion: String
    var duration: Int
    var completed: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        stretchName: String = "",
        bodyRegion: String = "",
        duration: Int = 0,
        completed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.stretchName = stretchName
        self.bodyRegion = bodyRegion
        self.duration = duration
        self.completed = completed
    }
}
