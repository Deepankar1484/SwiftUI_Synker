import SwiftUI

struct WakeUpScreen: View {
    @State private var wakeUpTime: String
    @State private var selectedTime: Date = Date()
    @State private var navigateToNextScreen: Bool = false

    init(settings: Settings) {
        _wakeUpTime = State(initialValue: settings.wakeUpTime)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) { // Align content to the left
                Text("When do you Wake Up?")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 40)

                Text("Synkr will help you start your day right.")
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack {
                    Spacer()
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .onChange(of: selectedTime) { newValue in
                            wakeUpTime = formatTime(date: newValue)
                        }
                    Spacer()
                }

                Spacer()

                Button(action: {
                    wakeUpTime = formatTime(date: selectedTime)
                    navigateToNextScreen = true
                }) {
                    Text("Continue")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding()
                .navigationDestination(isPresented: $navigateToNextScreen) {
                    BedtimeScreen(settings: Settings(
                        profilePicture: nil,
                        usage: .personal,
                        bedtime: "10:00 PM", // Placeholder, replace if needed
                        wakeUpTime: wakeUpTime,
                        notificationsEnabled: true
                    ))
                }
            }
            .padding()
        }
    }

    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    WakeUpScreen(settings: Settings(profilePicture: nil, usage: .personal, bedtime: "10:00 PM", wakeUpTime: "6:30 AM", notificationsEnabled: true))
}
