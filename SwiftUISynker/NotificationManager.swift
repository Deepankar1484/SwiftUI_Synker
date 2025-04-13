import SwiftUI
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var userPreference = false // Track user preference separately from system permission
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
                completion(granted)
            }
        }
    }
    
    // Set user preference to enabled
    func enableNotifications() {
        userPreference = true
        print("User preference set to enabled for notifications")
    }
    
    // Set user preference to disabled and clear pending notifications
    func disableNotifications() {
        userPreference = false
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All pending notifications removed and user preference set to disabled")
    }
    
    func scheduleTaskNotification(task: UserTask) {
        // First check if notifications are enabled in user preferences
        if !userPreference {
            print("Cannot schedule notification: user has disabled notifications in preferences")
            return
        }
        
        // Then check if we have system permission
        if !isAuthorized {
            requestAuthorization { granted in
                if granted {
                    self.createNotificationForTask(task)
                } else {
                    print("Cannot schedule notification: system permission denied")
                }
            }
        } else {
            createNotificationForTask(task)
        }
    }
    
    private func createNotificationForTask(_ task: UserTask) {
        // Calculate notification time based on task start time and alert preference
        let calendar = Calendar.current
        
        // Parse the start time string to create a proper notification date
        guard let startTimeDate = task.startTime.toDate(),
              let notificationDate = calendar.date(
                bySettingHour: calendar.component(.hour, from: startTimeDate),
                minute: calendar.component(.minute, from: startTimeDate),
                second: 0,
                of: task.date
              ) else {
            print("Failed to parse task time")
            return
        }
        
        // Calculate time offset based on alert preference
        var timeOffset: TimeInterval = 0
        
        switch task.alert {
        case .none:
            timeOffset = 0
        case .fiveMinutes:
            timeOffset = -5 * 60
        case .tenMinutes:
            timeOffset = -10 * 60
        case .fifteenMinutes:
            timeOffset = -15 * 60
        case .thirtyMinutes:
            timeOffset = -30 * 60
        case .oneHour:
            timeOffset = -60 * 60
        }
        
        let notificationTime = notificationDate.addingTimeInterval(timeOffset)
        
        // Only schedule if notification time is in the future
        guard notificationTime > Date() else {
            print("Cannot schedule notification in the past")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = task.taskName
        
        // Create message based on alert time
        var alertMessage: String
        switch task.alert {
        case .none:
            alertMessage = "Task starting now at \(task.startTime)⚡️"
        case .fiveMinutes:
            alertMessage = "Task starting in 5 minutes at \(task.startTime)⚡️"
        case .tenMinutes:
            alertMessage = "Task starting in 10 minutes at \(task.startTime)⚡️"
        case .fifteenMinutes:
            alertMessage = "Task starting in 15 minutes at \(task.startTime)⚡️"
        case .thirtyMinutes:
            alertMessage = "Task starting in 30 minutes at \(task.startTime)⚡️"
        case .oneHour:
            alertMessage = "Task starting in 1 hour at \(task.startTime)⚡️"
        }
        
        content.body = alertMessage
        content.sound = .default
        
        // Create date components trigger
        let triggerDateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Add the notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled for \(notificationTime)")
            }
        }
    }
    
    // Handle the notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}
