import Foundation
import SwiftData

enum SavedRoutineKind: String, Codable {
    case presetRoutine
    case livePersonalizedPlan
    case planSnapshot
}

@Model
final class SavedRoutine {
    var id: UUID
    var kindRaw: String
    var routineId: String?
    var stretchIds: [String]
    var displayTitle: String
    var displaySummary: String
    var durationSeconds: Int
    var createdAt: Date
    var updatedAt: Date

    var kind: SavedRoutineKind {
        get { SavedRoutineKind(rawValue: kindRaw) ?? .presetRoutine }
        set { kindRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        kind: SavedRoutineKind,
        routineId: String? = nil,
        stretchIds: [String] = [],
        displayTitle: String,
        displaySummary: String = "",
        durationSeconds: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.routineId = routineId
        self.stretchIds = stretchIds
        self.displayTitle = displayTitle
        self.displaySummary = displaySummary
        self.durationSeconds = durationSeconds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
