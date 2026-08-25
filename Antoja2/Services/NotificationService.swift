import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

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

    private func notificationID(for cravingID: String) -> String {
        "craving-follow-up-\(cravingID)"
    }
}
