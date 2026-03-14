import Foundation
import SwiftData

@Model
final class UserProfile {
    var primaryGoal: String
    var activityLevel: String
    var lifestyle: String
    var stretchingFrequency: String
    var dailyTime: String
    var tightnessSeverity: Int
    var problemAreas: [String]
    var problemTimes: [String]
    var commitmentDays: String
    var onboardingComplete: Bool
    var subscriptionActive: Bool

    init(
        primaryGoal: String = "",
        activityLevel: String = "",
        lifestyle: String = "",
        stretchingFrequency: String = "",
        dailyTime: String = "",
        tightnessSeverity: Int = 3,
        problemAreas: [String] = [],
        problemTimes: [String] = [],
        commitmentDays: String = "",
        onboardingComplete: Bool = false,
        subscriptionActive: Bool = false
    ) {
        self.primaryGoal = primaryGoal
        self.activityLevel = activityLevel
        self.lifestyle = lifestyle
        self.stretchingFrequency = stretchingFrequency
        self.dailyTime = dailyTime
        self.tightnessSeverity = tightnessSeverity
        self.problemAreas = problemAreas
        self.problemTimes = problemTimes
        self.commitmentDays = commitmentDays
        self.onboardingComplete = onboardingComplete
        self.subscriptionActive = subscriptionActive
    }
}
