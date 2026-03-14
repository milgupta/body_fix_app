import Foundation

enum OnboardingPainArea: String, CaseIterable, Identifiable {
    case neck
    case shoulders
    case upperBack
    case lowerBack
    case hips
    case hamstrings
    case knees
    case calves
    case ankles
    case wholeBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .neck: return "Neck"
        case .shoulders: return "Shoulders"
        case .upperBack: return "Upper Back"
        case .lowerBack: return "Lower Back"
        case .hips: return "Hips"
        case .hamstrings: return "Hamstrings"
        case .knees: return "Knees"
        case .calves: return "Calves"
        case .ankles: return "Ankles"
        case .wholeBody: return "Whole Body Stiffness"
        }
    }

    var emoji: String {
        switch self {
        case .neck: return "🦴"
        case .shoulders: return "💪"
        case .upperBack: return "🔙"
        case .lowerBack: return "⚡"
        case .hips: return "🦵"
        case .hamstrings: return "🏃"
        case .knees: return "🦿"
        case .calves: return "🦶"
        case .ankles: return "👟"
        case .wholeBody: return "🧍"
        }
    }
}
