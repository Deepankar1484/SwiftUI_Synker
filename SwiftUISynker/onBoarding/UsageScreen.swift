import SwiftUI
import Firebase

struct UsageScreen: View {
    @State private var selectedUsage: Usage? = nil
    @State private var navigateToNextScreen: Bool = false
    @State private var showAlert: Bool = false
    let userId: String

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                ProgressView(value: 0.2)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.red)
                    .padding(.top, 10)

                Text("How do you Plan to use Synkr?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 10)

                Text("Choose one option.")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                ForEach(Usage.allCases, id: \.self) { usage in
                    UsageSelectionRow(usage: usage, isSelected: selectedUsage == usage) {
                        selectedUsage = usage
                    }
                }

                Spacer()

                Button(action: continueAction) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .alert("Please select an option", isPresented: $showAlert) {
                    Button("OK", role: .cancel) {}
                }
                .fullScreenCover(isPresented: $navigateToNextScreen) {
                    WakeUpScreen(userId: userId, settings: createSettings())
                        .navigationBarHidden(true) // Hide navigation bar
                }
            }
            .padding()
        }
    }

    /// Creates an instance of `Settings` with the selected `usage`
    private func createSettings() -> Settings {
        return Settings(
            profilePicture: nil,
            usage: selectedUsage ?? .personal,
            bedtime: "10:00 PM",
            wakeUpTime: "6:30 AM",
            notificationsEnabled: true
        )
    }

    /// Handles continue button action
    private func continueAction() {
        if selectedUsage == nil {
            showAlert = true
        } else {
            navigateToNextScreen = true
        }
    }
}

// Supporting component for option selection
struct UsageSelectionRow: View {
    let usage: Usage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(usage.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// Preview
#Preview {
    UsageScreen(userId: "testUser123")
}
