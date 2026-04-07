import Foundation
import UIKit

enum BodyFixImageResolver {
    private static let cache = NSCache<NSString, UIImage>()

    private static let stretchOverrides: [String: String] = [
        "chest_doorway_double": "stretch_doorway_pec_stretch",
        "chest_corner_stretch": "stretch_pec_minor_corner_stretch",
        "chest_supine_foam": "stretch_supine_chest_stretch",
        "upperback_open_book": "stretch_seated_thoracic_rotation",
        "biceps_wall_stretch": "stretch_wall_biceps_stretch",
        "biceps_seated": "stretch_seated_bicep_floor_stretch",
        "biceps_horizon_bar": "stretch_spine_decompression_hang",
        "triceps_overhead": "stretch_overhead_tricep_stretch",
        "triceps_cross_reach": "stretch_cross_body_tricep_stretch",
        "triceps_towel": "stretch_seated_overhead_tricep_stretch",
        "forearms_prayer": "stretch_prayer_hands_stretch",
        "glutes_figure_four": "stretch_supine_figure_four",
        "glutes_lying_hug": "stretch_supine_glute_stretch",
        "glutes_seated_figure_four": "stretch_seated_figure_four_chair",
        "quads_side_lying": "stretch_prone_quad_stretch",
        "hamstrings_seated": "stretch_seated_hamstring_floor",
        "knees_heel_slides": "stretch_supine_knee_flexion",
        "calves_wall": "stretch_standing_calf_wall_stretch",
        "calves_stair_drop": "stretch_step_heel_drop",
        "calves_soleus": "stretch_soleus_bent_knee_stretch",
    ]

    private static let routineOverrides: [String: String] = [
        "sleep_wind_down": "routine_sleep",
        "sciatica_relief": "routine_sciatica",
        "tech_neck_fix": "routine_tech_neck",
        "splits_progression": "routine_splits",
        "post_workout_cool_down": "routine_post_workout",
        "upper_body_strength_stretch": "routine_upper_body",
        "shoulders_1": "routine_shoulders",
        "at_the_office": "routine_office",
        "it_band_release": "routine_it_band",
        "acl_recovery": "routine_acl",
        "carpal_tunnel_relief": "routine_carpal_tunnel",
        "herniated_disc_care": "routine_herniated_disc",
        "pre_workout_warm_up": "routine_pre_workout",
        "relax_unwind": "routine_relax",
        "posture_program": "routine_posture",
        "core_stability": "routine_core",
        "pelvic_floor_care": "routine_pelvic_floor",
        "neck_shoulders_1": "routine_neck_1",
        "neck_shoulders_2": "routine_neck_2",
        "neck_shoulders_3": "routine_neck_3",
    ]

    private static let areaNames: [MuscleGroup: String] = [
        .neck: "area_neck",
        .shoulders: "area_shoulders",
        .chest: "area_chest",
        .upperBack: "area_upper_back",
        .lowerBack: "area_lower_back",
        .core: "area_core",
        .hips: "area_hips",
        .glutes: "area_glutes",
        .quads: "area_quads",
        .hamstrings: "area_hamstrings",
        .calves: "area_calves",
    ]

    static func image(for stretch: Stretch) -> UIImage? {
        let candidates = unique(
            stretchOverrides[stretch.id],
            stretch.imageName,
            normalizedName("stretch_\(stretch.name)"),
            normalizedName("stretch_\(stretch.name)_stretch"),
            normalizedName("stretch_\(stretch.name)_pose"),
            normalizedName("stretch_\(stretch.name.replacingOccurrences(of: "Triceps", with: "Tricep"))"),
            normalizedName("stretch_\(stretch.name.replacingOccurrences(of: "Triceps", with: "Tricep"))_stretch"),
            normalizedName("stretch_\(stretch.name.replacingOccurrences(of: "Triceps", with: "Tricep"))_pose")
        )

        return resolve(candidates: candidates)
    }

    static func image(for routine: Routine) -> UIImage? {
        let candidates = unique(
            routineOverrides[routine.id],
            "routine_\(routine.id)",
            normalizedName("routine_\(routine.name)")
        )

        return resolve(candidates: candidates)
    }

    static func image(for muscleGroup: MuscleGroup) -> UIImage? {
        let candidates = unique(
            areaNames[muscleGroup],
            normalizedName("area_\(muscleGroup.displayName)")
        )

        return resolve(candidates: candidates)
    }

    private static func resolve(candidates: [String]) -> UIImage? {
        for name in candidates {
            let cacheKey = name as NSString
            if let cached = cache.object(forKey: cacheKey) {
                return cached
            }

            guard let image = UIImage(named: name) else { continue }
            cache.setObject(image, forKey: cacheKey)
            return image
        }

        return nil
    }

    private static func normalizedName(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "&", with: " and ")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: "_",
                options: .regularExpression
            )
            .replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }

    private static func unique(_ values: String?...) -> [String] {
        var seen = Set<String>()
        return values.compactMap { value in
            guard let value, !value.isEmpty, seen.insert(value).inserted else { return nil }
            return value
        }
    }
}
