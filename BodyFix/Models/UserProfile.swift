import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var bodyGoals: [String]
    var longTermGoal: String
    var painFrequency: Int
    var painImpact: Int
    var activityLevel: String
    var lifestyle: String
    var stretchingFrequency: String
    var dailyTime: String
    var problemAreas: [String]
    var problemTimes: [String]
    var commitmentDays: String
    var onboardingComplete: Bool
    var subscriptionActive: Bool

    init(
        name: String = "",
        bodyGoals: [String] = [],
        longTermGoal: String = "",
        painFrequency: Int = 3,
        painImpact: Int = 3,
        activityLevel: String = "",
        lifestyle: String = "",
        stretchingFrequency: String = "",
        dailyTime: String = "",
        problemAreas: [String] = [],
        problemTimes: [String] = [],
        commitmentDays: String = "",
        onboardingComplete: Bool = false,
        subscriptionActive: Bool = false
    ) {
        self.name = name
        self.bodyGoals = bodyGoals
        self.longTermGoal = longTermGoal
        self.painFrequency = painFrequency
        self.painImpact = painImpact
        self.activityLevel = activityLevel
        self.lifestyle = lifestyle
        self.stretchingFrequency = stretchingFrequency
        self.dailyTime = dailyTime
        self.problemAreas = problemAreas
        self.problemTimes = problemTimes
        self.commitmentDays = commitmentDays
        self.onboardingComplete = onboardingComplete
        self.subscriptionActive = subscriptionActive
    }
}
