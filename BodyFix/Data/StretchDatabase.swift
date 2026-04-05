import Foundation

enum StretchDatabase {
    static func loadAll() -> [Stretch] {
        loadJSONResource(named: "stretches", as: [Stretch].self) ?? []
    }

    static func loadAllRoutines() -> [Routine] {
        loadJSONResource(named: "routines", as: [Routine].self) ?? []
    }

    static func loadAllSeries() -> [RoutineSeries] {
        loadJSONResource(named: "routine_series", as: [RoutineSeries].self) ?? []
    }

    private static func loadJSONResource<T: Decodable>(named name: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(type, from: data)
        else {
            return nil
        }
        return value
    }

    /// Up to `perGroup` stretches per selected muscle group, in `MuscleGroup` order.
    static func stretches(for muscles: Set<MuscleGroup>, perGroup: Int? = nil) -> [Stretch] {
        groupedStretches(for: muscles, perGroup: perGroup).flatMap(\.1)
    }

    /// Grouped sections for list UI.
    static func groupedStretches(for muscles: Set<MuscleGroup>, perGroup: Int? = nil) -> [(MuscleGroup, [Stretch])] {
        let all = loadAll()
        var sections: [(MuscleGroup, [Stretch])] = []
        for group in MuscleGroup.allCases where muscles.contains(group) {
            let filtered = all.filter { $0.muscleGroup == group.rawValue }
            let items = perGroup.map { Array(filtered.prefix($0)) } ?? filtered
            if !items.isEmpty {
                sections.append((group, items))
            }
        }
        return sections
    }

    static func stretches(for routine: Routine) -> [Stretch] {
        routine.stretchIds.compactMap(stretch(id:))
    }

    static func stretches(for muscle: MuscleGroup) -> [Stretch] {
        loadAll().filter { $0.muscleGroup == muscle.rawValue }
    }

    static func stretch(id: String) -> Stretch? {
        loadAll().first { $0.id == id }
    }

    static func routine(id: String) -> Routine? {
        loadAllRoutines().first { $0.id == id }
    }

    static func series(id: String) -> RoutineSeries? {
        loadAllSeries().first { $0.id == id }
    }

    static func featuredRoutines(for profile: UserProfile?) -> [Routine] {
        var routines = routines(matching: .featured)
        guard let profile else { return routines }
        let firstId: String?
        if hasGoal("reduce pain", in: profile) || hasGoal("pain-free", in: profile) {
            firstId = "posture_reset"
        } else if hasGoal("recover faster from workouts", in: profile) || hasGoal("athletic performance", in: profile) {
            firstId = "wake_and_shake"
        } else if isDeskFocused(profile) {
            firstId = "desk_relief"
        } else if profile.problemTimes.contains(where: { $0.localizedCaseInsensitiveContains("before bed") }) {
            firstId = "sleep_wind_down"
        } else {
            firstId = "wake_up"
        }
        return prioritized(routines, leadingId: firstId)
    }

    static func recommendedRoutines(for profile: UserProfile?) -> [Routine] {
        let all = loadAllRoutines()
        var selectedIds: [String]
        if let profile, hasGoal("reduce pain", in: profile) || hasGoal("pain-free", in: profile) {
            selectedIds = ["lower_back_quick", "sciatica_relief", "tech_neck_fix", "hip_opener"]
        } else if let profile, hasGoal("improve flexibility", in: profile) {
            selectedIds = ["full_body_express", "hip_opener", "splits_progression", "leg_loosen"]
        } else if let profile, hasGoal("move better day-to-day", in: profile) || hasGoal("lasting stretch routine", in: profile) {
            selectedIds = ["posture_reset", "full_body_express", "shoulders_1", "glute_unlock"]
        } else if let profile, hasGoal("recover faster from workouts", in: profile) || hasGoal("athletic performance", in: profile) {
            selectedIds = ["post_workout_cool_down", "runners_recovery", "leg_loosen", "upper_body_strength_stretch"]
        } else {
            selectedIds = ["wake_and_shake", "hip_opener", "lower_back_quick", "tech_neck_fix"]
        }

        if let profile, isDeskFocused(profile) {
            for injected in ["desk_relief", "at_the_office"].reversed() {
                selectedIds.removeAll { $0 == injected }
                selectedIds.insert(injected, at: 0)
            }
        }

        let chosen = selectedIds.compactMap { id in all.first(where: { $0.id == id }) }
        return Array(chosen.prefix(4))
    }

    static func quickRoutines() -> [Routine] {
        let preferred = [
            "tech_neck_fix", "hip_opener", "shoulders_1", "lower_back_quick",
            "leg_loosen", "full_body_express", "wrist_rescue", "glute_unlock",
        ]
        return preferred.compactMap(routine(id:))
    }

    static func seriesRoutines(prioritizing profile: UserProfile?) -> [RoutineSeries] {
        let series = loadAllSeries()
        guard let profile else { return series }
        if let first = prioritizedSeriesId(for: profile) {
            return prioritized(series, leadingId: first)
        }
        return series
    }

    static func injuryRoutines(prioritizing profile: UserProfile?) -> [Routine] {
        sortByProfileRelevance(routines(matching: .injury), profile: profile)
    }

    static func activityRoutines() -> [Routine] {
        routines(matching: .activity)
    }

    static func browseAreas(prioritizing profile: UserProfile?) -> [MuscleGroup] {
        let base: [MuscleGroup] = [
            .neck, .shoulders, .chest, .upperBack, .lowerBack,
            .core, .hips, .glutes, .quads, .hamstrings, .calves,
        ]
        guard let profile else { return base }
        let preferred = profile.problemAreas.compactMap(muscleGroup(fromDisplayName:))
        return preferred + base.filter { !preferred.contains($0) }
    }

    static func searchAll(_ query: String) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let routines = loadAllRoutines()
            .filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
            .map(SearchResult.routine)
        let stretches = loadAll()
            .filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
            .map(SearchResult.stretch)
        return routines + stretches
    }

    static func levelRoutines(for series: RoutineSeries) -> [Routine] {
        series.levelRoutineIds.compactMap(routine(id:))
    }

    private static func routines(matching category: RoutineCategory) -> [Routine] {
        loadAllRoutines().filter { $0.hasCategory(category) }
    }

    private static func sortByProfileRelevance(_ routines: [Routine], profile: UserProfile?) -> [Routine] {
        guard let profile else { return routines }
        let areaNames = Set(profile.problemAreas.map { $0.lowercased() })
        return routines.sorted {
            relevanceScore(for: $0, areaNames: areaNames) > relevanceScore(for: $1, areaNames: areaNames)
        }
    }

    private static func relevanceScore(for routine: Routine, areaNames: Set<String>) -> Int {
        var score = 0
        for group in routine.relatedMuscleGroups where areaNames.contains(group.lowercased()) {
            score += 2
        }
        for tag in routine.tags where areaNames.contains(tag.lowercased()) {
            score += 1
        }
        return score
    }

    private static func prioritizedSeriesId(for profile: UserProfile) -> String? {
        let ordered = profile.problemAreas.map { $0.lowercased() }
        if ordered.contains(where: { $0.contains("lower back") }) { return "series_lower_back" }
        if ordered.contains(where: { $0.contains("neck") || $0.contains("shoulder") }) { return "series_neck_shoulders" }
        if ordered.contains(where: { $0.contains("hips") || $0.contains("glutes") }) { return "series_hips" }
        if hasGoal("posture", in: profile) { return "series_posture" }
        return nil
    }

    private static func prioritized<T: Identifiable>(_ values: [T], leadingId: T.ID?) -> [T] where T.ID: Equatable {
        guard let leadingId, let index = values.firstIndex(where: { $0.id == leadingId }) else { return values }
        var copy = values
        let first = copy.remove(at: index)
        copy.insert(first, at: 0)
        return copy
    }

    private static func muscleGroup(fromDisplayName name: String) -> MuscleGroup? {
        MuscleGroup.allCases.first { $0.displayName.caseInsensitiveCompare(name) == .orderedSame }
    }

    private static func hasGoal(_ needle: String, in profile: UserProfile) -> Bool {
        profile.bodyGoals.contains(where: { $0.localizedCaseInsensitiveContains(needle) })
            || profile.longTermGoal.localizedCaseInsensitiveContains(needle)
    }

    private static func isDeskFocused(_ profile: UserProfile) -> Bool {
        profile.lifestyle.localizedCaseInsensitiveContains("desk")
            || profile.activityLevel.localizedCaseInsensitiveContains("mostly sitting")
            || profile.problemTimes.contains(where: { $0.localizedCaseInsensitiveContains("sitting") })
    }
}
