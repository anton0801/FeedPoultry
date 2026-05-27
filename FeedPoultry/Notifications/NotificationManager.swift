import Foundation
import UserNotifications
import SwiftUI

final class NotificationManager: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init() {
        refreshAuthorization()
    }

    func refreshAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.refreshAuthorization()
                completion?(granted)
            }
        }
    }

    func scheduleDailyReminder(hour: Int, identifier: String = "fp.daily.reminder") {
        cancel(identifier: identifier)
        let content = UNMutableNotificationContent()
        content.title = "Feed Poultry"
        content.body = "Time to check feed and tasks for today."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func scheduleTask(_ task: FeedingTask) {
        cancel(identifier: task.id.uuidString)
        guard task.notify else { return }

        let content = UNMutableNotificationContent()
        content.title = "Feeding: \(task.title)"
        content.body = task.notes.isEmpty ? "Scheduled feeding reminder" : task.notes
        content.sound = .default

        let comps: DateComponents
        switch task.recurrence {
        case .once:
            comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.scheduledAt)
        case .daily:
            comps = Calendar.current.dateComponents([.hour, .minute], from: task.scheduledAt)
        case .weekly:
            comps = Calendar.current.dateComponents([.weekday, .hour, .minute], from: task.scheduledAt)
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: task.recurrence != .once)
        let req = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancel(id: String) { cancel(identifier: id) }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test notification"
        content.body = "Notifications are working ✓"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let req = UNNotificationRequest(identifier: "fp.test.\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
