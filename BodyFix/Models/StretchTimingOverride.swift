import Foundation
import SwiftData

enum StretchTimingOwnerKind: String, Codable {
    case presetRoutine
    case livePersonalizedPlan
    case savedPlanSnapshot
}

enum StretchOverrideMetric: String, Codable {
    case durationSeconds
    case repCount
}

@Model
final class StretchTimingOverride {
    var id: UUID
    var ownerKindRaw: String
    var ownerId: String
    var stretchId: String
    var metricRaw: String
    var value: Int
    var updatedAt: Date

    var ownerKind: StretchTimingOwnerKind {
        get { StretchTimingOwnerKind(rawValue: ownerKindRaw) ?? .presetRoutine }
        set { ownerKindRaw = newValue.rawValue }
    }

    var metric: StretchOverrideMetric {
        get { StretchOverrideMetric(rawValue: metricRaw) ?? .durationSeconds }
        set { metricRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        ownerKind: StretchTimingOwnerKind,
        ownerId: String,
        stretchId: String,
        metric: StretchOverrideMetric,
        value: Int,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerKindRaw = ownerKind.rawValue
        self.ownerId = ownerId
        self.stretchId = stretchId
        self.metricRaw = metric.rawValue
        self.value = value
        self.updatedAt = updatedAt
    }
}
