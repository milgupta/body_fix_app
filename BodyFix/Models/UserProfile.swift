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
    /// Consecutive days with at least one stretch session completed.
    var stretchStreak: Int
    /// Start-of-day normalized date of last session that updated the streak.
    var lastStretchActivityDate: Date?

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
        subscriptionActive: Bool = false,
        stretchStreak: Int = 0,
        lastStretchActivityDate: Date? = nil
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
        self.stretchStreak = stretchStreak
        self.lastStretchActivityDate = lastStretchActivityDate
    }
}
