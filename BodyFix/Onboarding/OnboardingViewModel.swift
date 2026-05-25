import Foundation
import SwiftData
import Observation

@Observable
class OnboardingViewModel {
    var currentStep: Int = 0
    let totalSteps: Int = 21

    // Screen 1: Name
    var userName: String = ""

    // Screen 2: Body Goals (multi-select, max 3)
    var selectedBodyGoals: Set<String> = []

    // Screen 3: Long-Term Goal
    var longTermGoal: String = ""

    // Screens 4: Validation (no input)

    // Screen 5: Pain Frequency (1-7)
    var painFrequency: Int = 3

    // Screen 6: Pain Impact (1-5)
    var painImpact: Int = 3

    // Screen 7: Build Program (no input)

    // Screen 8: Pain Awareness
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

    // Screen 9: Daily Movement
    var activityLevel: String = ""

    // Screen 10: Work/Lifestyle
    var lifestyle: String = ""

    // Screen 11: Problem Times
    var selectedProblemTimes: Set<String> = []

    // Screen 12: Stretching History
    var stretchingFrequency: String = ""

    // Screen 13: Time Commitment
    var dailyTime: String = ""

    // Screen 14: Education (no input)

    // Screen 15: Commitment
    var commitmentDays: String = ""

    // Screen 16: Health conditions (multi-select, optional)
    var selectedHealthConditions: Set<String> = []

    // Screen 17: Analyzing (no input)

    // Screen 18: Motivation Level
    var motivationLevel: String = ""

    // Screen 19: Fair Trial (no input)

    // Screen 20: Plan Preview (no input)

    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    var canAdvance: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !selectedBodyGoals.isEmpty
        case 3: return !longTermGoal.isEmpty
        case 4: return true
        case 5: return true
        case 6: return true
        case 7: return true
        case 8:
            guard !selectedPainAreas.isEmpty else { return false }
            if selectedPainAreas.contains(.other) {
                return !problemAreaOtherText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return true
        case 9: return !activityLevel.isEmpty
        case 10: return !lifestyle.isEmpty
        case 11: return !selectedProblemTimes.isEmpty
        case 12: return !stretchingFrequency.isEmpty
        case 13: return !dailyTime.isEmpty
        case 14: return true
        case 15: return !commitmentDays.isEmpty
        case 16: return true
        case 17: return true
        case 18: return !motivationLevel.isEmpty
        case 19: return true
        case 20: return true
        default: return false
        }
    }

    func advance() {
        guard currentStep < totalSteps - 1 else { return }
        HapticManager.shared.softImpact()
        currentStep += 1
    }

    func goBack() {
        guard currentStep > 0 else { return }
        HapticManager.shared.softImpact()
        currentStep -= 1
    }

    @discardableResult
    func saveProfile(to modelContext: ModelContext) -> UserProfile {
        let profile = UserProfile(
            name: userName,
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
            healthConditions: Array(selectedHealthConditions).sorted(),
            onboardingComplete: true
        )
        modelContext.insert(profile)
        return profile
    }
}
