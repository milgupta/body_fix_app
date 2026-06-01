import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let reminderPrefix = "stretch_reminder_"
    private let inactivityIdentifier = "stretch_inactivity_nudge"

    private init() {}

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                AnalyticsTracker.capture(granted ? "notification_permission_granted" : "notification_permission_declined")
                completion(granted)
            }
        }
    }

    func scheduleReminders(
        days: Set<Int>,
        hour: Int,
        minute: Int,
        problemArea: String?,
        completion: @escaping (Bool) -> Void
    ) {
        guard PaywallManager.shared.isSubscribed else {
            completion(false)
            return
        }

        removeReminderRequests()

        let group = DispatchGroup()
        let resultLock = NSLock()
        var didFail = false

        for day in days {
            var components = DateComponents()
            components.weekday = day
            components.hour = hour
            components.minute = minute

            let content = UNMutableNotificationContent()
            content.title = "Time to Stretch"
            content.body = message(problemArea: problemArea)
            content.sound = .default
            content.badge = nil

            let request = UNNotificationRequest(
                identifier: "\(reminderPrefix)\(day)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            )
            group.enter()
            UNUserNotificationCenter.current().add(request) { error in
                if error != nil {
                    resultLock.lock()
                    didFail = true
                    resultLock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            resultLock.lock()
            let succeeded = !didFail
            resultLock.unlock()

            if succeeded {
                ReminderStore.save(days: days, hour: hour, minute: minute)
                AnalyticsTracker.capture(
                    "notification_setup_saved",
                    properties: ["days": Array(days).sorted(), "hour": hour, "minute": minute]
                )
            } else {
                self.removeReminderRequests()
            }
            completion(succeeded)
        }
    }

    func scheduleInactivityNudge(problemArea: String?) {
        guard PaywallManager.shared.isSubscribed, ReminderStore.preferences.isEnabled else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [inactivityIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Your routine is waiting"
        if let problemArea, !problemArea.isEmpty {
            content.body = "A gentle reset for your \(problemArea.lowercased()) is ready when you are."
        } else {
            content.body = "A gentle stretch reset is ready when you are."
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3 * 24 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: inactivityIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        removeReminderRequests()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [inactivityIdentifier])
        ReminderStore.setEnabled(false)
    }

    private func removeReminderRequests() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
    }

    private func message(problemArea: String?) -> String {
        let area = problemArea?.lowercased()
        let messages = [
            "Good morning. A few minutes of stretching can set up your whole day.",
            "Quick reset? Your body will thank you.",
            area.map { "A gentle \($0) routine is ready." } ?? "A gentle stretch routine is ready.",
            "Even 3 minutes helps. Time to move.",
            "Your desk has held you still long enough. Time to stretch.",
        ]
        return messages.randomElement() ?? "Time for a quick stretch."
    }

    private var reminderIdentifiers: [String] {
        (1...7).map { "\(reminderPrefix)\($0)" }
    }
}
