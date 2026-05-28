import Foundation
import SwiftData

struct PersonalizedPlanRecommendation {
    let routine: Routine
    let stretches: [Stretch]
    let totalSeconds: Int
    let rationale: String
    let summary: String
    let focusAreas: [String]
}

enum PersonalizedPlanGenerator {
    static func recommendation(for profile: UserProfile) -> PersonalizedPlanRecommendation {
        let routines = StretchDatabase.loadAllRoutines()
        let bestRoutine = routines.max { lhs, rhs in
            score(for: lhs, profile: profile) < score(for: rhs, profile: profile)
        } ?? StretchDatabase.routine(id: "posture_reset")
        ?? StretchDatabase.loadAllRoutines().first
        ?? Routine(
            id: "posture_reset",
            name: "Posture Reset",
            categories: [.featured],
            stretchIds: [],
            relatedMuscleGroups: [],
            tags: [],
            durationMinutes: 4
        )

        let focusAreas = focusAreaLabels(from: profile)
        let stretches = generateStretches(for: bestRoutine, profile: profile)
        let totalSeconds = StretchTimingStore.totalDuration(for: stretches, overrides: [:])
        return PersonalizedPlanRecommendation(
            routine: bestRoutine,
            stretches: stretches,
            totalSeconds: totalSeconds,
            rationale: buildRationale(for: bestRoutine, profile: profile, selectedGroups: orderedProblemGroups(from: profile.problemAreas)),
            summary: buildSummary(for: profile, focusAreas: focusAreas),
            focusAreas: focusAreas
        )
    }

    @discardableResult
    static func upsertPlan(
        for profile: UserProfile,
        existing: PersonalizedPlan?,
        in modelContext: ModelContext
    ) -> PersonalizedPlan {
        let recommendation = recommendation(for: profile)
        let now = Date()

        if let existing {
            existing.routineId = recommendation.routine.id
            existing.stretchIds = recommendation.stretches.map(\.id)
            existing.targetDurationSeconds = recommendation.totalSeconds
            existing.updatedAt = now
            existing.sourceGoals = profile.bodyGoals
            existing.sourceProblemAreas = profile.problemAreas
            existing.sourceDailyTime = profile.dailyTime
            existing.sourceLifestyle = profile.lifestyle
            existing.rationale = recommendation.rationale
            existing.summary = recommendation.summary
            return existing
        }

        let plan = PersonalizedPlan(
            routineId: recommendation.routine.id,
            stretchIds: recommendation.stretches.map(\.id),
            targetDurationSeconds: recommendation.totalSeconds,
            createdAt: now,
            updatedAt: now,
            sourceGoals: profile.bodyGoals,
            sourceProblemAreas: profile.problemAreas,
            sourceDailyTime: profile.dailyTime,
            sourceLifestyle: profile.lifestyle,
            rationale: recommendation.rationale,
            summary: recommendation.summary
        )
        modelContext.insert(plan)
        return plan
    }

    static func stretches(for plan: PersonalizedPlan, fallbackProfile: UserProfile?) -> [Stretch] {
        let explicit = plan.stretchIds.compactMap(StretchDatabase.stretch(id:))
        if !explicit.isEmpty {
            return explicit
        }
        if let routine = StretchDatabase.routine(id: plan.routineId), let fallbackProfile {
            return generateStretches(for: routine, profile: fallbackProfile)
        }
        return []
    }

    private static func score(for routine: Routine, profile: UserProfile) -> Int {
        var total = 0
        let tags = Set(routine.tags.map(normalize))
        let groups = Set(routine.relatedMuscleGroups.map(normalize))
        let targetMinutes = parsedMinutes(from: profile.dailyTime)
        let commitmentDays = parsedCommitmentDays(from: profile.commitmentDays)
        let healthFlags = Set(profile.healthConditions.map(normalize))
        let problemGroups = mappedProblemGroups(from: profile.problemAreas)

        if routine.hasCategory(.recommendedCandidate) { total += 10 }
        if routine.hasCategory(.featured) { total += 7 }
        if routine.hasCategory(.quick) { total += 6 }
        if routine.hasCategory(.activity) { total += 3 }
        if routine.hasCategory(.injury) { total -= 3 }

        total += problemGroups.reduce(0) { partial, group in
            partial + (groups.contains(normalize(group.rawValue)) ? 7 : 0)
        }

        if profile.problemAreas.contains(where: { normalize($0).contains("whole body") }) {
            if tags.contains("daily-maintenance") { total += 4 }
            if tags.contains("flexibility") { total += 3 }
        }

        for goal in profile.bodyGoals.map(normalize) {
            if goal.contains("reduce pain") || goal.contains("pain-free") {
                if tags.contains("reduce-pain") { total += 9 }
                if routine.hasCategory(.injury) { total += 4 }
            }
            if goal.contains("improve flexibility") && tags.contains("flexibility") {
                total += 8
            }
            if goal.contains("improve posture") {
                if tags.contains("posture") { total += 10 }
                if tags.contains("desk") { total += 3 }
            }
            if goal.contains("recover faster") && tags.contains("recovery") {
                total += 8
            }
            if goal.contains("reduce stress") || goal.contains("sleep better") {
                if tags.contains("relax") || tags.contains("bedtime") {
                    total += 8
                }
            }
            if goal.contains("move better day to day") && tags.contains("daily-maintenance") {
                total += 8
            }
        }

        let longTermGoal = normalize(profile.longTermGoal)
        if longTermGoal.contains("pain-free") {
            if tags.contains("reduce-pain") { total += 6 }
            if tags.contains("posture") { total += 2 }
        }
        if longTermGoal.contains("lasting stretch routine") && tags.contains("daily-maintenance") {
            total += 6
        }
        if longTermGoal.contains("athletic performance") {
            if tags.contains("athletic") || tags.contains("recovery") || tags.contains("runner") {
                total += 7
            }
        }
        if longTermGoal.contains("mobility and ease") {
            if tags.contains("daily-maintenance") || tags.contains("flexibility") {
                total += 6
            }
        }

        let lifestyle = normalize(profile.lifestyle)
        if lifestyle.contains("desk") || lifestyle.contains("class") {
            if tags.contains("desk") { total += 8 }
            if tags.contains("posture") { total += 3 }
        }
        if lifestyle.contains("training") || lifestyle.contains("active job") {
            if tags.contains("recovery") || tags.contains("athletic") {
                total += 6
            }
        }
        if lifestyle.contains("feet") {
            if groups.contains("calves") || groups.contains("hips") || groups.contains("lowerback") {
                total += 4
            }
        }

        if targetMinutes > 0 {
            let routineMinutes = StretchDatabase.durationMinutes(for: routine)
            if routineMinutes <= targetMinutes {
                total += 8
            } else if routineMinutes <= targetMinutes + 2 {
                total += 4
            } else {
                total -= 4
            }
        }

        let routineMinutes = StretchDatabase.durationMinutes(for: routine)
        if commitmentDays <= 2 {
            if routine.hasCategory(.quick) { total += 5 }
            if routineMinutes <= 5 { total += 3 }
        } else if commitmentDays >= 5 {
            if tags.contains("daily-maintenance") || routine.hasCategory(.featured) {
                total += 4
            }
        }

        if healthFlags.contains("injury") && routine.hasCategory(.injury) {
            total += 6
        }
        if healthFlags.contains("sciatica") && normalize(routine.id).contains("sciatica") {
            total += 12
        }
        if healthFlags.contains("herniated disc") && normalize(routine.id).contains("herniated") {
            total += 12
        }
        if healthFlags.contains("chronic pain") || healthFlags.contains("fibromyalgia") {
            if tags.contains("reduce-pain") { total += 6 }
            if routineMinutes <= 5 { total += 3 }
        }
        if healthFlags.contains("pregnancy")
            || healthFlags.contains("osteoporosis")
            || healthFlags.contains("heart condition")
            || healthFlags.contains("high blood pressure")
        {
            if routineMinutes > 10 { total -= 5 }
            if tags.contains("athletic") || tags.contains("warmup") || tags.contains("post-workout") {
                total -= 3
            }
            if routine.hasCategory(.quick) || routine.hasCategory(.featured) {
                total += 2
            }
        }

        return total
    }

    private static func buildSummary(for profile: UserProfile, focusAreas: [String]) -> String {
        let lifestyle = normalize(profile.lifestyle)
        let areaPhrase = readableAreaPhrase(from: focusAreas)

        if let areaPhrase, lifestyle.contains("desk") || lifestyle.contains("class") {
            return "A simple routine built for \(areaPhrase), posture, and desk-heavy days."
        }
        if let areaPhrase {
            return "A simple routine built around your \(areaPhrase) needs and daily rhythm."
        }
        return "A simple routine built around what you told us."
    }

    private static func generateStretches(for routine: Routine, profile: UserProfile) -> [Stretch] {
        let routineStretches = StretchDatabase.stretches(for: routine)
        let allStretches = StretchDatabase.loadAll()
        let selectedGroups = orderedProblemGroups(from: profile.problemAreas)
        let targetWindow = durationWindow(for: profile, routine: routine)

        guard !routineStretches.isEmpty || !allStretches.isEmpty else { return [] }

        var chosen: [Stretch] = []
        var chosenIds = Set<String>()

        for group in selectedGroups {
            if chosen.contains(where: { $0.muscle == group }) {
                continue
            }

            if let candidate = bestCoverageStretch(
                for: group,
                in: routineStretches,
                chosenIds: chosenIds,
                preferredGroups: Set(selectedGroups),
                routine: routine
            ) ?? bestCoverageStretch(
                for: group,
                in: allStretches,
                chosenIds: chosenIds,
                preferredGroups: Set(selectedGroups),
                routine: routine
            ) {
                chosen.append(candidate)
                chosenIds.insert(candidate.id)
            }
        }

        let rankedCandidates = rankedStretchPool(
            routineStretches: routineStretches,
            allStretches: allStretches,
            preferredGroups: Set(selectedGroups),
            routine: routine
        )

        var running = totalDuration(of: chosen)

        for stretch in rankedCandidates where !chosenIds.contains(stretch.id) {
            if running < targetWindow.lowerBound {
                chosen.append(stretch)
                chosenIds.insert(stretch.id)
                running += stretch.duration
                continue
            }

            let proposed = running + stretch.duration
            if proposed <= targetWindow.upperBound,
               abs(targetWindow.target - proposed) < abs(targetWindow.target - running) {
                chosen.append(stretch)
                chosenIds.insert(stretch.id)
                running = proposed
            }
        }

        chosen = trimPlanIfHelpful(
            chosen,
            targetWindow: targetWindow,
            selectedGroups: selectedGroups
        )

        if chosen.isEmpty, let fallback = rankedCandidates.first {
            chosen = [fallback]
        }

        return chosen
    }

    private static func stretchScore(_ stretch: Stretch, preferredGroups: Set<MuscleGroup>, baseOrder: [String]) -> Int {
        var score = 0
        if let muscle = stretch.muscle, preferredGroups.contains(muscle) {
            score += 10
        }
        score += max(0, 8 - baseIndex(stretch, in: baseOrder))
        if stretch.duration <= 30 { score += 2 }
        if !stretch.isRepBased { score += 1 }
        return score
    }

    private static func baseIndex(_ stretch: Stretch, in ids: [String]) -> Int {
        ids.firstIndex(of: stretch.id) ?? ids.count
    }

    private static func buildRationale(for routine: Routine, profile: UserProfile, selectedGroups: [MuscleGroup]) -> String {
        var parts: [String] = []

        if !selectedGroups.isEmpty {
            parts.append(contentsOf: selectedGroups.prefix(2).map { $0.displayName.lowercased() })
        } else if let firstArea = profile.problemAreas.first {
            parts.append(firstArea.lowercased())
        }

        if profile.bodyGoals.contains(where: { normalize($0).contains("posture") }) {
            parts.append("posture support")
        } else if profile.bodyGoals.contains(where: { normalize($0).contains("reduce pain") }) {
            parts.append("pain relief")
        } else if profile.bodyGoals.contains(where: { normalize($0).contains("flexibility") }) {
            parts.append("mobility")
        }

        let lifestyle = normalize(profile.lifestyle)
        if lifestyle.contains("desk") || lifestyle.contains("class") {
            parts.append("desk-heavy days")
        } else if lifestyle.contains("training") {
            parts.append("training recovery")
        } else if lifestyle.contains("active job") {
            parts.append("active days")
        }

        let unique = Array(NSOrderedSet(array: parts)) as? [String] ?? parts
        let joined = unique.prefix(3).joined(separator: ", ")
        if !joined.isEmpty {
            return "Built for \(joined), using \(routine.name.lowercased()) as your main routine."
        }
        return "Built from your goals, time commitment, and target areas."
    }

    private static func focusAreaLabels(from profile: UserProfile) -> [String] {
        let selectedGroups = orderedProblemGroups(from: profile.problemAreas)
        if !selectedGroups.isEmpty {
            return Array(selectedGroups.prefix(3).map(\.displayName))
        }
        return Array(profile.problemAreas.prefix(3))
    }

    private static func orderedProblemGroups(from areas: [String]) -> [MuscleGroup] {
        var ordered: [MuscleGroup] = []
        for group in mappedProblemGroupsPreservingOrder(from: areas) where !ordered.contains(group) {
            ordered.append(group)
        }
        return ordered
    }

    private static func parsedMinutes(from value: String) -> Int {
        if value.contains("20+") { return 20 }
        let digits = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digits) ?? 0
    }

    private static func parsedCommitmentDays(from value: String) -> Int {
        if normalize(value).contains("every day") { return 7 }
        let digits = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digits) ?? 0
    }

    private static func mappedProblemGroups(from areas: [String]) -> Set<MuscleGroup> {
        Set(mappedProblemGroupsPreservingOrder(from: areas))
    }

    private static func mappedProblemGroupsPreservingOrder(from areas: [String]) -> [MuscleGroup] {
        var groups: [MuscleGroup] = []
        for area in areas {
            let normalized = normalize(area)
            if normalized == "ankles" {
                groups.append(.calves)
                continue
            }
            if normalized.contains("whole body") {
                continue
            }
            if let group = MuscleGroup.allCases.first(where: {
                normalize($0.rawValue) == normalized || normalize($0.displayName) == normalized
            }), !groups.contains(group) {
                groups.append(group)
            }
        }
        return groups
    }

    private static func durationWindow(for profile: UserProfile, routine: Routine) -> DurationWindow {
        let parsed = parsedMinutes(from: profile.dailyTime)
        let target = max(60, (parsed > 0 ? parsed : max(1, StretchDatabase.durationMinutes(for: routine))) * 60)
        return DurationWindow(
            target: target,
            lowerBound: max(60, target - 60),
            upperBound: target + 60
        )
    }

    private static func bestCoverageStretch(
        for group: MuscleGroup,
        in candidates: [Stretch],
        chosenIds: Set<String>,
        preferredGroups: Set<MuscleGroup>,
        routine: Routine
    ) -> Stretch? {
        candidates
            .filter { $0.muscle == group && !chosenIds.contains($0.id) }
            .sorted {
                compareStretches(
                    $0,
                    $1,
                    preferredGroups: preferredGroups,
                    baseOrder: routine.stretchIds
                )
            }
            .first
    }

    private static func rankedStretchPool(
        routineStretches: [Stretch],
        allStretches: [Stretch],
        preferredGroups: Set<MuscleGroup>,
        routine: Routine
    ) -> [Stretch] {
        var seen = Set<String>()
        let ordered = routineStretches + allStretches
        return ordered
            .filter { seen.insert($0.id).inserted }
            .sorted {
                compareStretches(
                    $0,
                    $1,
                    preferredGroups: preferredGroups,
                    baseOrder: routine.stretchIds
                )
            }
    }

    private static func compareStretches(
        _ lhs: Stretch,
        _ rhs: Stretch,
        preferredGroups: Set<MuscleGroup>,
        baseOrder: [String]
    ) -> Bool {
        let lhsScore = stretchScore(lhs, preferredGroups: preferredGroups, baseOrder: baseOrder)
        let rhsScore = stretchScore(rhs, preferredGroups: preferredGroups, baseOrder: baseOrder)
        if lhsScore == rhsScore {
            return baseIndex(lhs, in: baseOrder) < baseIndex(rhs, in: baseOrder)
        }
        return lhsScore > rhsScore
    }

    private static func trimPlanIfHelpful(
        _ stretches: [Stretch],
        targetWindow: DurationWindow,
        selectedGroups: [MuscleGroup]
    ) -> [Stretch] {
        var best = stretches
        var improved = true

        while improved {
            improved = false
            for candidate in best {
                let reduced = best.filter { $0.id != candidate.id }
                guard !reduced.isEmpty else { continue }
                guard preservesCoverage(reduced, requiredGroups: selectedGroups) else { continue }
                guard totalDuration(of: reduced) >= targetWindow.lowerBound else { continue }
                if abs(targetWindow.target - totalDuration(of: reduced)) < abs(targetWindow.target - totalDuration(of: best)) {
                    best = reduced
                    improved = true
                    break
                }
            }
        }

        return best
    }

    private static func preservesCoverage(_ stretches: [Stretch], requiredGroups: [MuscleGroup]) -> Bool {
        let covered = Set(stretches.compactMap(\.muscle))
        for group in requiredGroups where StretchDatabase.stretches(for: group).isEmpty == false {
            if !covered.contains(group) {
                return false
            }
        }
        return true
    }

    private static func totalDuration(of stretches: [Stretch]) -> Int {
        stretches.reduce(0) { $0 + $1.duration }
    }

    private static func readableAreaPhrase(from focusAreas: [String]) -> String? {
        let cleaned = focusAreas
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleaned.isEmpty else { return nil }
        if cleaned.count == 1 { return cleaned[0].lowercased() }
        if cleaned.count == 2 { return "\(cleaned[0].lowercased()) and \(cleaned[1].lowercased())" }
        return "\(cleaned[0].lowercased()), \(cleaned[1].lowercased()), and \(cleaned[2].lowercased())"
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }
}

private struct DurationWindow {
    let target: Int
    let lowerBound: Int
    let upperBound: Int
}
