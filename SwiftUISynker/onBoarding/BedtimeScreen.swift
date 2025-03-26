import SwiftUI

struct BedtimeScreen: View {
    @State private var bedtime: String
    @State private var selectedTime: Date = Date()
    @State private var showLogo = false
    @State private var moveLogoToTop = false
    @State private var showSuccessMessage = false
    @State private var navigateToHome = false
    @State private var showMainScreen = true

    init(settings: Settings) {
        _bedtime = State(initialValue: settings.bedtime)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if showMainScreen {
                    VStack(alignment: .leading) {
                        Text("When will you go to bed?")
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, 40)

                        Text("Setting a clear sleep goal can help regulate your body's internal clock.")
                            .foregroundColor(.gray)

                        Spacer()

                        HStack {
                            Spacer()
                            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            Spacer()
                        }

                        Spacer()

                        Button(action: {
                            bedtime = formatTime(date: selectedTime)
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
                        }) {
                            Text("Continue")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.black)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                    .padding()
                }

                if showLogo {
                    Image("Logo") // Replace with your actual logo asset name
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

                        Text("Your Account is now ready to use.")
                            .foregroundColor(.gray)
                            .opacity(showSuccessMessage ? 1 : 0)
                            .animation(.easeIn(duration: 0.7), value: showSuccessMessage)

                        Spacer()

                        Button(action: {
                            navigateToHome = true
                        }) {
                            Text("Proceed")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding()
                        .opacity(showSuccessMessage ? 1 : 0)
                        .animation(.easeIn(duration: 0.9), value: showSuccessMessage)
                    }
                    .padding()
                }
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
            }
            .onAppear {
                showLogo = false
                moveLogoToTop = false
                showSuccessMessage = false
            }
        }
    }

    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    BedtimeScreen(settings: Settings(profilePicture: nil, usage: .personal, bedtime: "10:00 PM", wakeUpTime: "6:30 AM", notificationsEnabled: true))
}
