import SwiftUI

struct WakeUpScreen: View {
    let userId: String
    @State var settings: Settings
    @State private var wakeUpTime: Date = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var navigateToNextScreen: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                ProgressView(value: 0.4)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.red)
                    .padding(.top, 10)

                Text("When do you usually wake up?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 10)

                Text("This helps us schedule your tasks efficiently.")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Custom Label Above DatePicker
                Text("Wake-Up Time")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                // Hide default label
                DatePicker("", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .padding()

                Spacer()

                Button(action: updateSettingsAndContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .navigationDestination(isPresented: $navigateToNextScreen) {
                    BedtimeScreen(userId: userId, settings: settings)
                }
            }
            .padding()
        }
    }

    /// Updates the `wakeUpTime` in settings and navigates to the next screen
    private func updateSettingsAndContinue() {
        settings.wakeUpTime = formatTime(wakeUpTime)
        navigateToNextScreen = true
    }

    /// Formats time to a user-friendly string
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// 🔥 SwiftUI Preview
#Preview {
    WakeUpScreen(userId: "testUser123", settings: Settings(
        profilePicture: nil,
        usage: .personal,
        bedtime: "10:00 PM",
        wakeUpTime: "6:30 AM",
        notificationsEnabled: true
    ))
}
