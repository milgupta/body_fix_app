import Foundation
import SwiftData
import Observation

@Observable
class OnboardingViewModel {
    var currentStep: Int = 0
    let totalSteps: Int = 21

    static let stepIdentifiers = [
        "welcome",
        "name",
        "age_range",
        "body_goals",
        "long_term_goal",
        "validation",
        "pain_frequency",
        "pain_impact",
        "build_program",
        "problem_areas",
        "activity_level",
        "lifestyle",
        "problem_times",
        "stretching_experience",
        "duration",
        "education",
        "commitment",
        "analyzing",
        "signature",
        "motivation",
        "plan_preview",
    ]

    // Screen 1: Name
    var userName: String = ""

    // Screen 2: Age Range
    var ageRange: String = ""

    // Screen 3: Body Goals (multi-select, max 3)
    var selectedBodyGoals: Set<String> = []

    // Screen 4: Long-Term Goal
    var longTermGoal: String = ""

    // Screen 5: Validation (no input)

    // Screen 6: Pain Frequency (1-7)
    var painFrequency: Int = 3

    // Screen 7: Pain Impact (1-5)
    var painImpact: Int = 3

    // Screen 8: Build Program (no input)

    // Screen 9: Pain Awareness
    var selectedPainAreas: Set<OnboardingPainArea> = []
    var problemAreaOtherText: String = ""

    var problemAreasForProfile: [String] {
        var areas = selectedPainAreas.filter { $0 != .other }.map(\.rawValue)
        if selectedPainAreas.contains(.other) {
            let custom = problemAreaOtherText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !custom.isEmpty {
                areas.append(custom)
            }
        }
        return areas
    }

    // Screen 10: Daily Movement
    var activityLevel: String = ""

    // Screen 11: Work/Lifestyle
    var lifestyle: String = ""

    // Screen 12: Problem Times
    var selectedProblemTimes: Set<String> = []

    // Screen 13: Stretching History
    var stretchingFrequency: String = ""

    // Screen 14: Time Commitment
    var dailyTime: String = ""

    // Screen 15: Education (no input)

    // Screen 16: Commitment
    var commitmentDays: String = ""

    // Screen 17: Analyzing (no input)

    // Screen 18: Signature Commitment (kept only for this onboarding session)
    var commitmentSignatureStrokes: [[CGPoint]] = []

    // Screen 19: Motivation Level
    var motivationLevel: String = ""

    // Screen 20: Plan Preview (no input)

    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    func analyticsProperties(for step: Int? = nil) -> [String: Any] {
        let index = step ?? currentStep
        var properties: [String: Any] = [
            "step_id": Self.stepIdentifiers.indices.contains(index) ? Self.stepIdentifiers[index] : "unknown",
            "step_index": index,
            "step_number": index + 1,
            "total_steps": totalSteps,
        ]
        if !ageRange.isEmpty {
            properties["age_range"] = ageRange
        }
        return properties
    }

    var canAdvance: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !ageRange.isEmpty
        case 3: return !selectedBodyGoals.isEmpty
        case 4: return !longTermGoal.isEmpty
        case 5: return true
        case 6: return true
        case 7: return true
        case 8: return true
        case 9:
            guard !selectedPainAreas.isEmpty else { return false }
            if selectedPainAreas.contains(.other) {
                return !problemAreaOtherText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return true
        case 10: return !activityLevel.isEmpty
        case 11: return !lifestyle.isEmpty
        case 12: return !selectedProblemTimes.isEmpty
        case 13: return !stretchingFrequency.isEmpty
        case 14: return !dailyTime.isEmpty
        case 15: return true
        case 16: return !commitmentDays.isEmpty
        case 17: return true
        case 18: return !commitmentSignatureStrokes.isEmpty
        case 19: return !motivationLevel.isEmpty
        case 20: return true
        default: return false
        }
    }

    func advance() {
        guard currentStep < totalSteps - 1 else { return }
        currentStep += 1
    }

    func goBack() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    @discardableResult
    func saveProfile(to modelContext: ModelContext) -> UserProfile {
        let profile = UserProfile(
            name: userName,
            ageRange: ageRange,
            bodyGoals: Array(selectedBodyGoals),
            longTermGoal: longTermGoal,
            painFrequency: painFrequency,
            painImpact: painImpact,
            activityLevel: activityLevel,
            lifestyle: lifestyle,
            stretchingFrequency: stretchingFrequency,
            dailyTime: dailyTime,
            problemAreas: problemAreasForProfile,
            problemTimes: Array(selectedProblemTimes),
            commitmentDays: commitmentDays,
            onboardingComplete: true
        )
        modelContext.insert(profile)
        return profile
    }
}
