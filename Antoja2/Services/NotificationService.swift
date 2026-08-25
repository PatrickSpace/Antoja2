import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    private let dailyPendingPrefix = "daily-pending-summary-"
    private let dailyReminderHorizon = 30

    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    func scheduleFollowUp(for craving: Craving) async {
        guard await requestAuthorizationIfNeeded() else { return }

        let content = UNMutableNotificationContent()
        content.title = "¿Cómo te fue con tu antojo?"
        content.body = "Abre Antoja2 y registra si lo comiste o no."
        content.sound = .default
        content.userInfo = ["cravingID": craving.id]

        let interval = max(craving.followUpDueAt.timeIntervalSinceNow, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationID(for: craving.id),
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelFollowUp(for cravingID: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID(for: cravingID)])
    }

    func syncDailyPendingReminders(pendingCount: Int) async {
        guard pendingCount > 1 else {
            await cancelDailyPendingReminders()
            return
        }
        guard await requestAuthorizationIfNeeded() else { return }

        let center = UNUserNotificationCenter.current()
        let existingIdentifiers = Set(
            await center.pendingNotificationRequests()
                .map(\.identifier)
                .filter { $0.hasPrefix(dailyPendingPrefix) }
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "es_PE")
        calendar.timeZone = TimeZone(identifier: "America/Lima") ?? .current

        guard
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()),
            let firstReminder = calendar.date(
                bySettingHour: 7,
                minute: 0,
                second: 0,
                of: tomorrow
            )
        else { return }

        for dayOffset in 0..<dailyReminderHorizon {
            guard let reminderDate = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: firstReminder
            ) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Tienes decisiones pendientes"
            content.body = "Abre Antoja2 y completa tus antojos pendientes."
            content.sound = .default
            content.userInfo = ["destination": "pending-cravings"]

            var components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )
            components.timeZone = calendar.timeZone

            let identifier = "\(dailyPendingPrefix)\(Int(reminderDate.timeIntervalSince1970))"
            guard !existingIdentifiers.contains(identifier) else { continue }

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelDailyPendingReminders() async {
        let center = UNUserNotificationCenter.current()
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(dailyPendingPrefix) }
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func notificationID(for cravingID: String) -> String {
        "craving-follow-up-\(cravingID)"
    }
}
