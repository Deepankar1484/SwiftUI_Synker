import SwiftUI

struct UsageScreen: View {
    @State private var selectedUsage: Usage? = nil
    @State private var navigateToNextScreen: Bool = false
    @State private var showAlert: Bool = false

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

                // ✅ Selection List (Only one can be selected)
                ForEach(Usage.allCases, id: \.self) { usage in
                    UsageSelectionRow(usage: usage, isSelected: selectedUsage == usage) {
                        selectedUsage = usage
                    }
                }

                Spacer()

                // ✅ Continue Button
                Button(action: {
                    if selectedUsage == nil {
                        showAlert = true
                    } else {
                        navigateToNextScreen = true
                    }
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
                
                .navigationDestination(isPresented: $navigateToNextScreen) {
                    WakeUpScreen(settings: Settings(
                        profilePicture: nil,
                        usage: selectedUsage ?? .personal, // Default fallback
                        bedtime: "10:00 PM",
                        wakeUpTime: "6:30 AM",
                        notificationsEnabled: true
                    ))
                }
            }
            .padding()
        }
    }
}

// ✅ Single Selection Row
struct UsageSelectionRow: View {
    let usage: Usage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: usageIcon(for: usage))
                    .foregroundColor(.purple)
                    .frame(width: 30)

                Text(usage.rawValue)
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Circle()
                    .stroke(isSelected ? Color.purple : Color.gray, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.purple : Color.clear)
                            .frame(width: 10, height: 10)
                    )
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
        }
    }

    func usageIcon(for usage: Usage) -> String {
        switch usage {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .education: return "books.vertical.fill"
        }
    }
}

// ✅ Preview
#Preview {
    UsageScreen()
}
