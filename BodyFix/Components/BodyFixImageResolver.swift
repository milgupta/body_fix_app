import Foundation
import UIKit

enum BodyFixImageResolver {
    private static let cache = NSCache<NSString, UIImage>()

    private static let stretchOverrides: [String: String] = [
        "chest_doorway_double": "stretch_doorway_pec_stretch",
        "chest_corner_stretch": "stretch_pec_minor_corner_stretch",
        "chest_supine_foam": "stretch_supine_chest_stretch",
        "upperback_open_book": "stretch_seated_thoracic_rotation",
        "biceps_wall_stretch": "stretch_bicep_wall_stretch",
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
        "lower_back_pain_relief": "routine_lower_back_quick",
        "knee_pain_relief": "routine_acl",
        "hip_flexor_tight_hips": "routine_hip_opener",
        "shoulder_impingement_relief": "routine_frozen_shoulder",
        "piriformis_syndrome_relief": "routine_sciatica",
        "tennis_golf_elbow": "routine_wrist_rescue",
        "upper_back_rhomboid_pain": "routine_tech_neck_recovery",
        "ankle_sprain_recovery": "routine_plantar_fasciitis",
        "hip_bursitis_relief": "routine_it_band",
        "neck_pain_stiffness": "routine_tech_neck",
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

    private static let areaStretchFallbacks: [MuscleGroup: String] = [
        .biceps: "stretch_bicep_wall_stretch",
        .triceps: "stretch_overhead_tricep_stretch",
        .forearms: "stretch_prayer_hands_stretch",
        .knees: "stretch_supine_knee_flexion",
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
            areaStretchFallbacks[muscleGroup],
            normalizedName("area_\(muscleGroup.displayName)")
        )

        return resolve(candidates: candidates)
    }

    static func beforeImage(for stretch: Stretch) -> UIImage? {
        guard let imageName = beforeImageName(for: stretch) else { return nil }
        return resolveBundledPNG(candidates: [imageName], inDirectory: "images/images_before")
    }

    static func afterImage(for stretch: Stretch) -> UIImage? {
        let candidates = unique(
            "endframe_\(stretch.id)",
            normalizedName("endframe_\(stretch.imageName.removingPrefix("stretch_"))"),
            normalizedName("endframe_\(stretch.imageName)")
        )

        return resolveBundledPNG(candidates: candidates, inDirectory: "images/images_after")
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

    private static func resolveBundledPNG(candidates: [String], inDirectory directory: String) -> UIImage? {
        for name in candidates {
            let cacheKey = "\(directory)/\(name)" as NSString
            if let cached = cache.object(forKey: cacheKey) {
                return cached
            }

            guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: directory)
                ?? Bundle.main.url(forResource: name, withExtension: "png"),
                  let image = UIImage(contentsOfFile: url.path)
            else {
                continue
            }

            cache.setObject(image, forKey: cacheKey)
            return image
        }

        return nil
    }

    private static func beforeImageName(for stretch: Stretch) -> String? {
        let position = stretch.position?.lowercased()
        let support = stretch.support?.lowercased()

        switch (position, support) {
        case ("standing", "wall"):
            return "before_standing_wall_side"
        case ("standing", "doorway"):
            return "before_standing_doorway_side"
        case ("standing", _):
            return "before_standing_none_front"
        case ("seated", "chair"):
            return "before_seated_chair_3quarter"
        case ("seated", _):
            return "before_seated_floor_3quarter"
        case ("lying", "wall"):
            return "before_lying_wall_side"
        case ("lying", _):
            return "before_lying_floor_3quarter"
        default:
            return nil
        }
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

private extension String {
    func removingPrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
}
