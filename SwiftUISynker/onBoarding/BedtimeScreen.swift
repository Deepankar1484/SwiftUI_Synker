import SwiftUI
import FirebaseFirestore

struct BedtimeScreen: View {
    var userId: String
    @State private var settings: Settings
    @State private var bedtimeTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showLogo = false
    @State private var moveLogoToTop = false
    @State private var showSuccessMessage = false
    @State private var contentOpacity: Double = 1.0
    
    init(userId: String, settings: Settings) {
        self.userId = userId
        _settings = State(initialValue: settings)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main Content
                VStack(alignment: .leading, spacing: 20) {
                    ProgressView(value: 0.8)
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(.red)
                        .padding(.top, 10)
                    
                    Text("When will you go to bed?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text("Setting a clear sleep goal can help regulate your body's internal clock.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Bedtime")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    DatePicker("", selection: $bedtimeTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .padding()
                    
                    Spacer()
                    
                    Button(action: updateBedtimeAndContinue) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .opacity(contentOpacity)
                .animation(.easeInOut(duration: 0.5), value: contentOpacity)
                
                // Success Animation
                if showLogo {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .offset(y: moveLogoToTop ? -UIScreen.main.bounds.height / 3 : 0)
                        .animation(.easeInOut(duration: 1.0), value: moveLogoToTop)
                        .transition(.opacity.combined(with: .scale))
                }
                
                if showSuccessMessage {
                    VStack {
                        Spacer()
                        
                        Text("Amazing!")
                            .font(.largeTitle)
                            .bold()
                            .transition(.scale.combined(with: .opacity))
                        
                        Text("Your account is now ready to use.")
                            .foregroundColor(.gray)
                            .transition(.opacity)
                        
                        Spacer()
                        
                        Button(action: navigateToAuthenticationView) {
                            Text("Proceed To Login")
                                .foregroundColor(.white)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom))
                    }
                    .padding()
                    .transition(.opacity)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func updateBedtimeAndContinue() {
        settings.bedtime = formatTime(date: bedtimeTime)
        
        // First fade out the content
        withAnimation(.easeInOut(duration: 0.5)) {
            contentOpacity = 0
        }
        
        let db = Firestore.firestore()
        let updatedSettings: [String: Any] = [
            "profilePicture": settings.profilePicture ?? "",
            "usage": settings.usage.rawValue,
            "bedtime": settings.bedtime,
            "wakeUpTime": settings.wakeUpTime,
            "notificationsEnabled": false
        ]
        
        db.collection("users").document(userId).updateData([
            "settings": updatedSettings
        ]) { error in
            if let error = error {
                print("Error updating settings: \(error.localizedDescription)")
                // If error, fade content back in
                withAnimation {
                    contentOpacity = 1
                }
            } else {
                // Show logo animation
                withAnimation(.spring()) {
                    showLogo = true
                }
                
                // Sequence the animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        moveLogoToTop = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.spring()) {
                            showSuccessMessage = true
                        }
                    }
                }
            }
        }
    }
    
    private func navigateToAuthenticationView() {
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView:
                NavigationStack {
                    AuthenticationView()
                }
            )
            window.makeKeyAndVisible()
        }
    }

    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
