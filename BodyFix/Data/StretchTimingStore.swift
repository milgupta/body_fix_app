import Foundation
import SwiftData

enum StretchTimingStore {
    static let adjustmentStep = 15
    static let minimumDuration = 15
    static let repAdjustmentStep = 1
    static let minimumRepCount = 1
    static let livePlanOwnerId = "live_personalized_plan"

    static func overrideMap(
        kind: StretchTimingOwnerKind,
        ownerId: String,
        metric: StretchOverrideMetric,
        overrides: [StretchTimingOverride]
    ) -> [String: Int] {
        Dictionary(
            uniqueKeysWithValues: overrides
                .filter { $0.ownerKind == kind && $0.ownerId == ownerId && $0.metric == metric }
                .map { ($0.stretchId, $0.value) }
        )
    }

    static func durationOverrideMap(
        kind: StretchTimingOwnerKind,
        ownerId: String,
        overrides: [StretchTimingOverride]
    ) -> [String: Int] {
        overrideMap(kind: kind, ownerId: ownerId, metric: .durationSeconds, overrides: overrides)
    }

    static func repOverrideMap(
        kind: StretchTimingOwnerKind,
        ownerId: String,
        overrides: [StretchTimingOverride]
    ) -> [String: Int] {
        overrideMap(kind: kind, ownerId: ownerId, metric: .repCount, overrides: overrides)
    }

    static func effectiveDuration(for stretch: Stretch, overrides: [String: Int]) -> Int {
        overrides[stretch.id] ?? stretch.duration
    }

    static func effectiveRepCount(for stretch: Stretch, overrides: [String: Int]) -> Int {
        overrides[stretch.id] ?? stretch.targetReps
    }

    static func totalDuration(for stretches: [Stretch], overrides: [String: Int]) -> Int {
        stretches.reduce(0) { $0 + effectiveDuration(for: $1, overrides: overrides) }
    }

    static func timerRoute(
        stretchIds: [String],
        startIndex: Int,
        routineName: String? = nil,
        seriesId: String? = nil,
        seriesLevel: Int? = nil,
        durationOverrides: [String: Int],
        repOverrides: [String: Int] = [:]
    ) -> StretchTimerRoute {
        StretchTimerRoute(
            stretchIds: stretchIds,
            startIndex: startIndex,
            routineName: routineName,
            seriesId: seriesId,
            seriesLevel: seriesLevel,
            durationOverrides: durationOverrides,
            repOverrides: repOverrides
        )
    }

    static func detailText(
        for stretch: Stretch,
        durationOverrides: [String: Int],
        repOverrides: [String: Int] = [:]
    ) -> String {
        let duration = effectiveDuration(for: stretch, overrides: durationOverrides)
        let repCount = effectiveRepCount(for: stretch, overrides: repOverrides)
        let trimmedScheme = stretch.repScheme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedScheme.isEmpty else {
            return stretch.isRepBased ? repCountLabel(repCount) : "\(duration)s"
        }

        if stretch.isRepBased {
            if let range = trimmedScheme.range(of: #"\d+"#, options: .regularExpression) {
                let updated = trimmedScheme.replacingCharacters(in: range, with: "\(repCount)")
                return updated
            }
            return "\(repCountLabel(repCount)) · \(trimmedScheme)"
        }

        let baseDuration = "\(stretch.duration)s"
        if trimmedScheme.localizedCaseInsensitiveContains(baseDuration) {
            return trimmedScheme.replacingOccurrences(
                of: baseDuration,
                with: "\(duration)s",
                options: .caseInsensitive
            )
        }

        if trimmedScheme.localizedCaseInsensitiveContains("\(duration)s") {
            return trimmedScheme
        }

        return "\(duration)s · \(trimmedScheme)"
    }

    static func setDuration(
        for stretch: Stretch,
        durationSeconds: Int,
        ownerKind: StretchTimingOwnerKind,
        ownerId: String,
        overrides: [StretchTimingOverride],
        in modelContext: ModelContext
    ) {
        let clamped = max(minimumDuration, durationSeconds)
        setValue(
            for: stretch,
            value: clamped,
            defaultValue: stretch.duration,
            metric: .durationSeconds,
            ownerKind: ownerKind,
            ownerId: ownerId,
            overrides: overrides,
            in: modelContext
        )
    }

    static func setRepCount(
        for stretch: Stretch,
        repCount: Int,
        ownerKind: StretchTimingOwnerKind,
        ownerId: String,
        overrides: [StretchTimingOverride],
        in modelContext: ModelContext
    ) {
        let clamped = max(minimumRepCount, repCount)
        setValue(
            for: stretch,
            value: clamped,
            defaultValue: stretch.targetReps,
            metric: .repCount,
            ownerKind: ownerKind,
            ownerId: ownerId,
            overrides: overrides,
            in: modelContext
        )
    }

    static func adjustedDuration(
        for stretch: Stretch,
        delta: Int,
        overrides: [String: Int]
    ) -> Int {
        max(minimumDuration, effectiveDuration(for: stretch, overrides: overrides) + delta)
    }

    static func adjustedRepCount(
        for stretch: Stretch,
        delta: Int,
        overrides: [String: Int]
    ) -> Int {
        max(minimumRepCount, effectiveRepCount(for: stretch, overrides: overrides) + delta)
    }

    static func controlLabel(
        for stretch: Stretch,
        durationOverrides: [String: Int],
        repOverrides: [String: Int] = [:]
    ) -> String {
        if stretch.isRepBased {
            return repCountLabel(effectiveRepCount(for: stretch, overrides: repOverrides))
        }
        return "\(effectiveDuration(for: stretch, overrides: durationOverrides))s"
    }

    static func repCountLabel(_ reps: Int) -> String {
        reps == 1 ? "1 rep" : "\(reps) reps"
    }

    static func durationLabel(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes > 0 && remainder > 0 { return "\(minutes)m \(remainder)s" }
        if minutes > 0 { return minutes == 1 ? "1 min" : "\(minutes) min" }
        return "\(seconds)s"
    }

    static func minutesLabel(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes > 0 && remainder > 0 { return "\(minutes)m \(remainder)s" }
        if minutes > 0 { return minutes == 1 ? "1 minute" : "\(minutes) minutes" }
        return seconds == 1 ? "1 second" : "\(seconds) seconds"
    }

    private static func setValue(
        for stretch: Stretch,
        value: Int,
        defaultValue: Int,
        metric: StretchOverrideMetric,
        ownerKind: StretchTimingOwnerKind,
        ownerId: String,
        overrides: [StretchTimingOverride],
        in modelContext: ModelContext
    ) {
        let existing = overrides.first {
            $0.ownerKind == ownerKind
                && $0.ownerId == ownerId
                && $0.stretchId == stretch.id
                && $0.metric == metric
        }

        if value == defaultValue {
            if let existing {
                modelContext.delete(existing)
            }
            return
        }

        if let existing {
            existing.value = value
            existing.updatedAt = .now
            return
        }

        modelContext.insert(
            StretchTimingOverride(
                ownerKind: ownerKind,
                ownerId: ownerId,
                stretchId: stretch.id,
                metric: metric,
                value: value
            )
        )
    }
}
