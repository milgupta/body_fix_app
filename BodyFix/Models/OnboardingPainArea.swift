import Foundation

enum OnboardingPainArea: String, CaseIterable, Identifiable {
    case neck
    case biceps
    case triceps
    case chest
    case upperBack
    case core
    case lowerBack
    case hips
    case glutes
    case quads
    case hamstrings
    case knees
    case calves
    case ankles
    case wholeBody
    case other

    var id: String { rawValue }

    var analyticsID: String {
        switch self {
        case .upperBack: return "upper_back"
        case .lowerBack: return "lower_back"
        case .wholeBody: return "whole_body"
        default: return rawValue
        }
    }

    var displayName: String {
        switch self {
        case .neck: return "Neck"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .chest: return "Chest"
        case .upperBack: return "Upper Back"
        case .core: return "Core"
        case .lowerBack: return "Lower Back"
        case .hips: return "Hips"
        case .glutes: return "Glutes"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .knees: return "Knees"
        case .calves: return "Calves"
        case .ankles: return "Ankles"
        case .wholeBody: return "Whole Body Stiffness"
        case .other: return "Other"
        }
    }

    var emoji: String {
        switch self {
        case .neck: return "🦴"
        case .biceps: return "💪"
        case .triceps: return "🦾"
        case .chest: return "🫁"
        case .upperBack: return "🔙"
        case .core: return "🧘"
        case .lowerBack: return "⚡"
        case .hips: return "🦵"
        case .glutes: return "🍑"
        case .quads: return "🦵"
        case .hamstrings: return "🏃"
        case .knees: return "🦿"
        case .calves: return "🦶"
        case .ankles: return "👟"
        case .wholeBody: return "🧍"
        case .other: return "✏️"
        }
    }
}
