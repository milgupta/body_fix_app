import Foundation

struct AnalyticsSnapshot {
    let flexometerScore: Int
    let currentStreak: Int
    let longestStreak: Int
    let sessionsThisWeek: Int
    let minutesThisWeek: Int
    let hasSessions: Bool
    let supportMessage: String
}

enum AnalyticsCalculator {
    private static let streakTarget = 7
    private static let sessionsTarget = 5
    private static let minutesTarget = 60

    static func snapshot(
        profile: UserProfile?,
        sessions: [StretchSession],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> AnalyticsSnapshot {
        let normalizedDays = uniqueSessionDays(from: sessions, calendar: calendar)
        let currentStreak = currentStreakLength(days: normalizedDays, now: now, calendar: calendar)
        let longestStreak = longestStreakLength(days: normalizedDays, calendar: calendar)

        let weekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        let weeklySessions = sessions.filter { $0.date >= weekStart }
        let sessionsThisWeek = weeklySessions.count
        let minutesThisWeek = weeklySessions.reduce(0) { $0 + max($1.totalDuration, 0) } / 60

        let streakPoints = min(Double(max(currentStreak, profile?.stretchStreak ?? 0)) / Double(streakTarget), 1) * 40
        let sessionPoints = min(Double(sessionsThisWeek) / Double(sessionsTarget), 1) * 35
        let minutePoints = min(Double(minutesThisWeek) / Double(minutesTarget), 1) * 25
        let score = max(0, min(Int(round(streakPoints + sessionPoints + minutePoints)), 100))

        return AnalyticsSnapshot(
            flexometerScore: score,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            sessionsThisWeek: sessionsThisWeek,
            minutesThisWeek: minutesThisWeek,
            hasSessions: sessions.isEmpty == false,
            supportMessage: supportMessage(
                hasSessions: sessions.isEmpty == false,
                score: score,
                sessionsThisWeek: sessionsThisWeek,
                currentStreak: currentStreak
            )
        )
    }

    private static func supportMessage(
        hasSessions: Bool,
        score: Int,
        sessionsThisWeek: Int,
        currentStreak: Int
    ) -> String {
        guard hasSessions else {
            return "Complete your first stretch session to start building your Flexometer."
        }

        if score >= 80 {
            return "You are building strong momentum. Keep your routine steady to stay in the green."
        }

        if currentStreak >= 3 {
            return "Your streak is doing the heavy lifting. A few more minutes this week will push you higher."
        }

        if sessionsThisWeek >= 2 {
            return "You are warming up nicely. Keep showing up this week to raise your Flexometer."
        }

        return "A little consistency goes a long way. One more session will start moving this score up."
    }

    private static func uniqueSessionDays(from sessions: [StretchSession], calendar: Calendar) -> [Date] {
        let days = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        return days.sorted()
    }

    private static func currentStreakLength(days: [Date], now: Date, calendar: Calendar) -> Int {
        guard days.isEmpty == false else { return 0 }

        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let anchor: Date
        if days.contains(today) {
            anchor = today
        } else if days.contains(yesterday) {
            anchor = yesterday
        } else {
            return 0
        }

        return streakLength(endingAt: anchor, within: Set(days), calendar: calendar)
    }

    private static func longestStreakLength(days: [Date], calendar: Calendar) -> Int {
        let daySet = Set(days)
        return days.reduce(0) { longest, day in
            max(longest, streakLength(endingAt: day, within: daySet, calendar: calendar))
        }
    }

    private static func streakLength(endingAt endDate: Date, within days: Set<Date>, calendar: Calendar) -> Int {
        var streak = 0
        var cursor: Date? = endDate

        while let day = cursor, days.contains(day) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: day)
        }

        return streak
    }
}
