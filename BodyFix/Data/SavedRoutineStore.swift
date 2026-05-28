import Foundation
import SwiftData

enum SavedRoutineStore {
    static func livePlanFavorite(in saved: [SavedRoutine]) -> SavedRoutine? {
        saved.first(where: { $0.kind == .livePersonalizedPlan })
    }

    static func presetFavorite(for routineId: String, in saved: [SavedRoutine]) -> SavedRoutine? {
        saved.first(where: { $0.kind == .presetRoutine && $0.routineId == routineId })
    }

    static func isLivePlanSaved(in saved: [SavedRoutine]) -> Bool {
        livePlanFavorite(in: saved) != nil
    }

    @discardableResult
    static func togglePreset(
        routine: Routine,
        saved: [SavedRoutine],
        in modelContext: ModelContext
    ) -> Bool {
        if let existing = presetFavorite(for: routine.id, in: saved) {
            modelContext.delete(existing)
            return false
        }

        let favorite = SavedRoutine(
            kind: .presetRoutine,
            routineId: routine.id,
            stretchIds: routine.stretchIds,
            displayTitle: routine.name,
            displaySummary: "\(routine.stretchIds.count) stretches",
            durationSeconds: resolvedDuration(for: routine)
        )
        modelContext.insert(favorite)
        return true
    }

    @discardableResult
    static func toggleLivePlan(
        plan: PersonalizedPlan,
        routine: Routine?,
        saved: [SavedRoutine],
        in modelContext: ModelContext
    ) -> Bool {
        if let existing = livePlanFavorite(in: saved) {
            modelContext.delete(existing)
            return false
        }

        let favorite = SavedRoutine(
            kind: .livePersonalizedPlan,
            routineId: plan.routineId,
            stretchIds: plan.stretchIds,
            displayTitle: "Your current plan",
            displaySummary: plan.summary,
            durationSeconds: resolvedDuration(for: plan, routine: routine)
        )
        modelContext.insert(favorite)
        return true
    }

    static func savePlanSnapshot(
        plan: PersonalizedPlan,
        routine: Routine?,
        title: String,
        summary: String,
        in modelContext: ModelContext
    ) {
        let snapshot = SavedRoutine(
            kind: .planSnapshot,
            routineId: routine?.id ?? plan.routineId,
            stretchIds: plan.stretchIds,
            displayTitle: title,
            displaySummary: summary,
            durationSeconds: resolvedDuration(for: plan, routine: routine)
        )
        modelContext.insert(snapshot)
    }

    static func refreshLivePlanFavorite(
        plan: PersonalizedPlan,
        routine: Routine?,
        saved: [SavedRoutine]
    ) {
        guard let existing = livePlanFavorite(in: saved) else { return }
        existing.routineId = plan.routineId
        existing.stretchIds = plan.stretchIds
        existing.displayTitle = "Your current plan"
        existing.displaySummary = plan.summary
        existing.durationSeconds = resolvedDuration(for: plan, routine: routine)
        existing.updatedAt = .now
    }

    private static func resolvedDuration(for plan: PersonalizedPlan, routine: Routine?) -> Int {
        if plan.targetDurationSeconds > 0 {
            return plan.targetDurationSeconds
        }
        if let routine {
            return resolvedDuration(for: routine)
        }
        return 0
    }

    private static func resolvedDuration(for routine: Routine) -> Int {
        let seconds = StretchDatabase.totalDurationSeconds(for: routine)
        return seconds > 0 ? seconds : routine.durationMinutes * 60
    }
}
