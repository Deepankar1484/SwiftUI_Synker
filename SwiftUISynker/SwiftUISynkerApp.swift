import SwiftUI
import Firebase

@main
struct SwiftUISynkerApp: App {
    
     @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
   // @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        FirebaseApp.configure()
        print("Firebase successfully connected!")
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AuthenticationView()
            }
        }
    }
}
