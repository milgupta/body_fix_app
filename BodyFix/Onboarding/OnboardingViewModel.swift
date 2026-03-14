import Foundation
import SwiftData
import Observation

@Observable
class OnboardingViewModel {
    var currentStep: Int = 0
    let totalSteps: Int = 13

    // Screen 2: Pain Awareness
    var selectedPainAreas: Set<OnboardingPainArea> = []

    // Screen 3: Daily Movement
    var activityLevel: String = ""

    // Screen 4: Work/Lifestyle
    var lifestyle: String = ""

    // Screen 5: Tightness Severity
    var tightnessSeverity: Int = 3

    // Screen 6: Problem Times
    var selectedProblemTimes: Set<String> = []

    // Screen 7: Stretching History
    var stretchingFrequency: String = ""

    // Screen 8: Goals
    var primaryGoal: String = ""

    // Screen 9: Time Commitment
    var dailyTime: String = ""

    // Screen 11: Commitment
    var commitmentDays: String = ""

    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    var canAdvance: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !selectedPainAreas.isEmpty
        case 2: return !activityLevel.isEmpty
        case 3: return !lifestyle.isEmpty
        case 4: return true
        case 5: return !selectedProblemTimes.isEmpty
        case 6: return !stretchingFrequency.isEmpty
        case 7: return !primaryGoal.isEmpty
        case 8: return !dailyTime.isEmpty
        case 9: return true
        case 10: return !commitmentDays.isEmpty
        case 11: return true
        case 12: return true
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

    func saveProfile(to modelContext: ModelContext) {
        let profile = UserProfile(
            primaryGoal: primaryGoal,
            activityLevel: activityLevel,
            lifestyle: lifestyle,
            stretchingFrequency: stretchingFrequency,
            dailyTime: dailyTime,
            tightnessSeverity: tightnessSeverity,
            problemAreas: selectedPainAreas.map(\.rawValue),
            problemTimes: Array(selectedProblemTimes),
            commitmentDays: commitmentDays,
            onboardingComplete: true
        )
        modelContext.insert(profile)
    }
}
