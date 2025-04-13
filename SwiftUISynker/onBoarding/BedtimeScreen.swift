import SwiftUI
import FirebaseFirestore

struct BedtimeScreen: View {
    var userId: String
    @State private var settings: Settings
    @State private var selectedTime: Date = Date()
    @State private var showLogo = false
    @State private var moveLogoToTop = false
    @State private var showSuccessMessage = false
    @State private var navigateToHome = false
    @State private var showMainScreen = true
    
    // Add this for programmatic navigation
    @Environment(\.dismiss) private var dismiss
    
    init(userId: String, settings: Settings) {
        self.userId = userId
        _settings = State(initialValue: settings)
    }

    var body: some View {
        ZStack {
            if showMainScreen {
                VStack(alignment: .leading, spacing: 20) {
                    // 🔴 Progress Bar at the Top
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

                    Spacer()

                    // 📅 Centered DatePicker
                    HStack {
                        Spacer()
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                        Spacer()
                    }

                    Spacer()

                    Button(action: {
                        settings.bedtime = formatTime(date: selectedTime)
                        updateBedtimeInFirestore()
                    }) {
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
            }

            if showLogo {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .offset(y: moveLogoToTop ? -UIScreen.main.bounds.height / 3 : 0)
                    .animation(.easeInOut(duration: 1), value: moveLogoToTop)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            moveLogoToTop = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                showSuccessMessage = true
                            }
                        }
                    }
            }

            if showSuccessMessage {
                VStack {
                    Spacer()

                    Text("Amazing!")
                        .font(.largeTitle)
                        .bold()
                        .opacity(showSuccessMessage ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: showSuccessMessage)

                    Text("Your account is now ready to use.")
                        .foregroundColor(.gray)
                        .opacity(showSuccessMessage ? 1 : 0)
                        .animation(.easeIn(duration: 0.7), value: showSuccessMessage)

                    Spacer()

                    Button(action: {
                        // Replace current navigation stack with AuthenticationView
                        navigateToAuthenticationView()
                    }) {
                        Text("Proceed To Login")
                            .foregroundColor(.white)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .opacity(showSuccessMessage ? 1 : 0)
                    .animation(.easeIn(duration: 0.9), value: showSuccessMessage)
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true) // Hide the back button in this screen
    }

    private func updateBedtimeInFirestore() {
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
            } else {
                withAnimation {
                    showMainScreen = false
                    showLogo = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    moveLogoToTop = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showSuccessMessage = true
                    }
                }
            }
        }
    }
    
    private func navigateToAuthenticationView() {
        // This will programmatically replace the entire navigation stack with AuthenticationView
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
