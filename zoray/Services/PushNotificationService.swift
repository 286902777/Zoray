import UIKit
import UserNotifications

final class PushNotificationService {
    static let shared = PushNotificationService()

    private var hasRequestedAuthorization = false

    private init() {}

    func requestAuthorizationIfNeeded() {
        guard hasRequestedAuthorization == false else { return }
        hasRequestedAuthorization = true

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization()
            case .authorized, .provisional, .ephemeral:
                self.registerForRemoteNotifications()
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            guard granted else { return }
            self?.registerForRemoteNotifications()
        }
    }

    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
