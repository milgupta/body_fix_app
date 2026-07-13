import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var ageRange: String
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
    /// Legacy field retained for SwiftData store compatibility; no longer collected or used.
    var healthConditions: [String]
    var onboardingComplete: Bool
    var subscriptionActive: Bool
    /// Consecutive days with at least one stretch session completed.
    var stretchStreak: Int = 0
    /// Start-of-day normalized date of last session that updated the streak.
    var lastStretchActivityDate: Date?

    init(
        name: String = "",
        ageRange: String = "",
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
        healthConditions: [String] = [],
        onboardingComplete: Bool = false,
        subscriptionActive: Bool = false,
        stretchStreak: Int = 0,
        lastStretchActivityDate: Date? = nil
    ) {
        self.name = name
        self.ageRange = ageRange
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
        self.healthConditions = healthConditions
        self.onboardingComplete = onboardingComplete
        self.subscriptionActive = subscriptionActive
        self.stretchStreak = stretchStreak
        self.lastStretchActivityDate = lastStretchActivityDate
    }
}
