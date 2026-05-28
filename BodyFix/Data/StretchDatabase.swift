import Foundation

enum StretchDatabase {
    private static let excludedStretchIds: Set<String> = [
        "open_book_stretch",
        "foam_roller_thoracic_extension",
    ]

    private static let legacyStretchAliases: [String: String] = [
        "neck_chin_tuck": "chin_tuck",
        "neck_upper_trap_stretch": "upper_trapezius_stretch",
        "neck_rotation_mobility": "neck_rotation_stretch",
        "shoulders_cross_body": "cross_body_shoulder_stretch",
        "shoulders_doorway_pec": "doorway_pec_stretch",
        "shoulders_sleeper": "sleeper_stretch",
        "chest_doorway_double": "doorway_pec_stretch",
        "chest_corner_stretch": "pec_minor_corner_stretch",
        "chest_supine_foam": "supine_chest_stretch",
        "upperback_thread_needle": "thread_the_needle",
        "upperback_cat_cow": "cat_cow",
        "upperback_open_book": "seated_thoracic_rotation",
        "lowerback_child_pose": "childs_pose",
        "lowerback_knee_to_chest": "knee_to_chest_stretch",
        "lowerback_supine_twist": "supine_spinal_twist",
        "core_pelvic_tilt": "pelvic_tilt",
        "biceps_wall_stretch": "bicep_wall_stretch",
        "biceps_seated": "seated_bicep_floor_stretch",
        "biceps_horizon_bar": "spine_decompression_hang",
        "triceps_overhead": "overhead_tricep_stretch",
        "triceps_cross_reach": "cross_body_tricep_stretch",
        "triceps_towel": "seated_overhead_tricep_stretch",
        "forearms_extensor": "wrist_extensor_stretch",
        "forearms_flexor": "wrist_flexor_stretch",
        "forearms_prayer": "prayer_hands_stretch",
        "hips_pigeon": "pigeon_pose",
        "hips_hip_flexor_lunge": "kneeling_hip_flexor_stretch",
        "hips_butterfly": "butterfly_stretch",
        "glutes_figure_four": "supine_figure_four",
        "glutes_lying_hug": "supine_glute_stretch",
        "glutes_seated_figure_four": "seated_figure_four_chair",
        "quads_standing": "standing_quad_stretch",
        "quads_side_lying": "prone_quad_stretch",
        "quads_prone": "prone_quad_stretch",
        "hamstrings_standing_fold": "standing_forward_fold",
        "hamstrings_seated": "seated_hamstring_floor",
        "hamstrings_supine_strap": "supine_hamstring_towel",
        "knees_heel_slides": "supine_knee_flexion",
        "calves_wall": "standing_calf_wall_stretch",
        "calves_stair_drop": "step_heel_drop",
        "calves_soleus": "soleus_bent_knee_stretch",
    ]

    private static let primaryStretches: [Stretch] = loadPrimaryStretches()
    private static let legacyFallbackStretches: [Stretch] = loadJSONResource(named: "stretches", as: [Stretch].self) ?? []

    static func loadAll() -> [Stretch] {
        primaryStretches
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

    static func totalDurationSeconds(for routine: Routine) -> Int {
        StretchTimingStore.totalDuration(for: stretches(for: routine), overrides: [:])
    }

    static func durationMinutes(for routine: Routine) -> Int {
        let seconds = totalDurationSeconds(for: routine)
        guard seconds > 0 else { return routine.durationMinutes }
        return max(1, Int(ceil(Double(seconds) / 60.0)))
    }

    static func durationLabel(for routine: Routine) -> String {
        let minutes = durationMinutes(for: routine)
        guard minutes > 0 else { return routine.durationLabel }
        return minutes == 1 ? "1 min" : "\(minutes) min"
    }

    static func invitingDurationLabel(for routine: Routine) -> String {
        let minutes = durationMinutes(for: routine)
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }

    static func stretches(for muscle: MuscleGroup) -> [Stretch] {
        loadAll().filter { $0.muscleGroup == muscle.rawValue }
    }

    static func stretch(id: String) -> Stretch? {
        if let stretch = primaryStretches.first(where: { $0.id == id }) {
            return stretch
        }
        if let alias = legacyStretchAliases[id],
           let stretch = primaryStretches.first(where: { $0.id == alias }) {
            return stretch
        }
        return legacyFallbackStretches.first(where: { $0.id == id })
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
            .lowerBack, .neck, .shoulders, .knees, .hips,
            .upperBack, .hamstrings, .calves, .glutes, .quads,
            .core, .chest, .biceps, .triceps, .forearms,
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

    private static func loadPrimaryStretches() -> [Stretch] {
        let rawStretches = loadJSONResource(named: "stretches_v2_150", as: [RawStretchV2].self) ?? []
        return rawStretches.compactMap(normalizeStretch)
    }

    private static func normalizeStretch(_ raw: RawStretchV2) -> Stretch? {
        guard !excludedStretchIds.contains(raw.id),
              let primaryGroup = raw.primaryMuscleGroup,
              let imageName = raw.image?.name,
              !imageName.isEmpty
        else {
            return nil
        }

        return Stretch(
            id: raw.id,
            name: raw.name,
            muscleGroup: primaryGroup.rawValue,
            duration: raw.timing.durationValue,
            repScheme: raw.timing.repScheme,
            description: raw.description,
            difficulty: raw.numericDifficulty,
            imageName: imageName,
            position: raw.position,
            support: raw.support
        )
    }
}

private struct RawStretchV2: Decodable {
    let id: String
    let name: String
    let muscleGroups: [String]
    let timing: RawStretchTiming
    let description: String
    let difficulty: String
    let position: String?
    let support: String?
    let image: RawStretchImage?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case muscleGroups = "muscle_groups"
        case timing
        case description
        case difficulty
        case position
        case support
        case image
    }

    var primaryMuscleGroup: MuscleGroup? {
        muscleGroups.lazy.compactMap(MuscleGroup.init(v2Identifier:)).first
    }

    var numericDifficulty: Int {
        switch difficulty.lowercased() {
        case "beginner":
            return 1
        case "intermediate":
            return 2
        case "advanced":
            return 3
        default:
            return 2
        }
    }
}

private struct RawStretchTiming: Decodable {
    let holdSeconds: Int?
    let perSide: Bool
    let reps: Int?
    let cycles: Int?
    let type: String
    let display: String

    enum CodingKeys: String, CodingKey {
        case holdSeconds = "hold_seconds"
        case perSide = "per_side"
        case reps
        case cycles
        case type
        case display
    }

    var durationValue: Int {
        let multiplier = max(1, cycles ?? 1) * (perSide ? 2 : 1)
        if let holdSeconds, holdSeconds > 0 {
            let repMultiplier = max(1, reps ?? 1)
            return holdSeconds * repMultiplier * multiplier
        }
        if let reps, reps > 0 {
            return reps * multiplier * 3
        }
        return 30 * multiplier
    }

    var repScheme: String {
        let trimmedDisplay = display.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDisplay.isEmpty {
            return trimmedDisplay
        }

        if let reps, reps > 0 {
            let prefix = (cycles ?? 1) > 1 ? "\(cycles ?? 1) x " : ""
            return "\(prefix)\(reps) reps"
        }

        let suffix = perSide ? " each side" : ""
        return "\(durationValue)s\(suffix)"
    }
}

private struct RawStretchImage: Decodable {
    let name: String
}

private extension MuscleGroup {
    init?(v2Identifier: String) {
        switch v2Identifier {
        case "neck":
            self = .neck
        case "shoulders":
            self = .shoulders
        case "chest":
            self = .chest
        case "upper_back":
            self = .upperBack
        case "lower_back":
            self = .lowerBack
        case "core":
            self = .core
        case "biceps":
            self = .biceps
        case "triceps":
            self = .triceps
        case "forearms":
            self = .forearms
        case "hips":
            self = .hips
        case "glutes":
            self = .glutes
        case "quads":
            self = .quads
        case "hamstrings":
            self = .hamstrings
        case "knees":
            self = .knees
        case "calves":
            self = .calves
        default:
            return nil
        }
    }
}
