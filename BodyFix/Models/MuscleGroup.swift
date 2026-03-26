import Foundation

enum MuscleGroup: String, CaseIterable, Identifiable, Codable, Hashable {
    case neck, shoulders, chest, upperBack, lowerBack, core
    case biceps, triceps, forearms
    case hips, glutes, quads, hamstrings, knees, calves

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .neck: return "Neck"
        case .shoulders: return "Shoulders"
        case .chest: return "Chest"
        case .upperBack: return "Upper Back"
        case .lowerBack: return "Lower Back"
        case .core: return "Core"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .forearms: return "Forearms"
        case .hips: return "Hips"
        case .glutes: return "Glutes"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .knees: return "Knees"
        case .calves: return "Calves"
        }
    }

    var imageName: String {
        "muscle_\(rawValue)"
    }
}
