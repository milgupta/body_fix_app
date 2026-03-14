import Foundation

enum BodyRegion: String, CaseIterable, Identifiable {
    case neck
    case shoulders
    case upperBack
    case lowerBack
    case chest
    case hips
    case glutes
    case hamstrings
    case quads
    case calves

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .neck: return "Neck"
        case .shoulders: return "Shoulders"
        case .upperBack: return "Upper Back"
        case .lowerBack: return "Lower Back"
        case .chest: return "Chest"
        case .hips: return "Hips / Hip Flexors"
        case .glutes: return "Glutes"
        case .hamstrings: return "Hamstrings"
        case .quads: return "Quads"
        case .calves: return "Calves"
        }
    }

    var iconName: String {
        switch self {
        case .neck: return "figure.head"
        case .shoulders: return "figure.arms.open"
        case .upperBack: return "figure.stand"
        case .lowerBack: return "figure.flexibility"
        case .chest: return "figure.strengthtraining.traditional"
        case .hips: return "figure.walk"
        case .glutes: return "figure.run"
        case .hamstrings: return "figure.cooldown"
        case .quads: return "figure.step.training"
        case .calves: return "figure.hiking"
        }
    }
}
