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

        let focusAreas = Array(profile.problemAreas.prefix(3))
        let stretches = generateStretches(for: bestRoutine, profile: profile)
        let totalSeconds = stretches.reduce(0) { $0 + $1.duration }
        return PersonalizedPlanRecommendation(
            routine: bestRoutine,
            stretches: stretches,
            totalSeconds: totalSeconds,
            rationale: buildRationale(for: bestRoutine, profile: profile),
            summary: buildSummary(for: profile),
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
            if routine.durationMinutes <= targetMinutes {
                total += 8
            } else if routine.durationMinutes <= targetMinutes + 2 {
                total += 4
            } else {
                total -= 4
            }
        }

        if commitmentDays <= 2 {
            if routine.hasCategory(.quick) { total += 5 }
            if routine.durationMinutes <= 5 { total += 3 }
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
            if routine.durationMinutes <= 5 { total += 3 }
        }
        if healthFlags.contains("pregnancy")
            || healthFlags.contains("osteoporosis")
            || healthFlags.contains("heart condition")
            || healthFlags.contains("high blood pressure")
        {
            if routine.durationMinutes > 10 { total -= 5 }
            if tags.contains("athletic") || tags.contains("warmup") || tags.contains("post-workout") {
                total -= 3
            }
            if routine.hasCategory(.quick) || routine.hasCategory(.featured) {
                total += 2
            }
        }

        return total
    }

    private static func buildSummary(for profile: UserProfile) -> String {
        let topArea = profile.problemAreas.first?.lowercased()
        let lifestyle = normalize(profile.lifestyle)

        if let topArea, lifestyle.contains("desk") || lifestyle.contains("class") {
            return "A simple routine built for \(topArea), posture, and desk-heavy days."
        }
        if let topArea {
            return "A simple routine built around your \(topArea) needs and daily rhythm."
        }
        return "A simple routine built around what you told us."
    }

    private static func generateStretches(for routine: Routine, profile: UserProfile) -> [Stretch] {
        let allStretches = StretchDatabase.stretches(for: routine)
        guard !allStretches.isEmpty else { return [] }

        let targetSeconds = max(60, parsedMinutes(from: profile.dailyTime) * 60)
        let preferredGroups = mappedProblemGroups(from: profile.problemAreas)

        let prioritized = allStretches.sorted { lhs, rhs in
            let lhsScore = stretchScore(lhs, preferredGroups: preferredGroups, baseOrder: routine.stretchIds)
            let rhsScore = stretchScore(rhs, preferredGroups: preferredGroups, baseOrder: routine.stretchIds)
            if lhsScore == rhsScore {
                return baseIndex(lhs, in: routine.stretchIds) < baseIndex(rhs, in: routine.stretchIds)
            }
            return lhsScore > rhsScore
        }

        var chosen: [Stretch] = []
        var running = 0
        let minimumCount = minimumStretchCount(for: targetSeconds)

        for stretch in prioritized {
            let proposed = running + stretch.duration
            if chosen.count < minimumCount || proposed <= targetSeconds {
                chosen.append(stretch)
                running = proposed
            }
        }

        if chosen.isEmpty, let first = prioritized.first {
            chosen = [first]
        }

        let chosenIds = Set(chosen.map(\.id))
        return allStretches.filter { chosenIds.contains($0.id) }
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

    private static func minimumStretchCount(for targetSeconds: Int) -> Int {
        switch targetSeconds {
        case ..<180: return 3
        case ..<300: return 4
        case ..<600: return 5
        default: return 6
        }
    }

    private static func baseIndex(_ stretch: Stretch, in ids: [String]) -> Int {
        ids.firstIndex(of: stretch.id) ?? ids.count
    }

    private static func buildRationale(for routine: Routine, profile: UserProfile) -> String {
        var parts: [String] = []

        if let firstArea = profile.problemAreas.first {
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
        var groups = Set<MuscleGroup>()
        for area in areas {
            let normalized = normalize(area)
            if normalized == "ankles" {
                groups.insert(.calves)
                continue
            }
            if normalized.contains("whole body") {
                continue
            }
            if let group = MuscleGroup.allCases.first(where: {
                normalize($0.rawValue) == normalized || normalize($0.displayName) == normalized
            }) {
                groups.insert(group)
            }
        }
        return groups
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }
}
