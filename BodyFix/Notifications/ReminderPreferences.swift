import Foundation

struct ReminderPreferences {
    var isEnabled: Bool
    var days: Set<Int>
    var hour: Int?
    var minute: Int?

    var hasCompleteSchedule: Bool {
        !days.isEmpty && hour != nil && minute != nil
    }
}

enum ReminderStore {
    static let enabledKey = "notification_enabled"
    static let daysKey = "notification_days"
    static let hourKey = "notification_hour"
    static let minuteKey = "notification_minute"

    static var preferences: ReminderPreferences {
        let defaults = UserDefaults.standard
        let rawDays = defaults.array(forKey: daysKey) as? [Int] ?? []
        let hour = defaults.object(forKey: hourKey) as? Int
        let minute = defaults.object(forKey: minuteKey) as? Int
        return ReminderPreferences(
            isEnabled: defaults.bool(forKey: enabledKey),
            days: Set(rawDays),
            hour: hour,
            minute: minute
        )
    }

    static func save(days: Set<Int>, hour: Int, minute: Int, enabled: Bool = true) {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
        UserDefaults.standard.set(Array(days).sorted(), forKey: daysKey)
        UserDefaults.standard.set(hour, forKey: hourKey)
        UserDefaults.standard.set(minute, forKey: minuteKey)
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
    }
}
