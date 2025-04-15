import SwiftUI

struct StartPlanningScreen: View {
    let userId: String // Accept userId as a parameter
    @State private var navigateToUsageScreen = false
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("Let's get started by planning today...")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("This will only take a few steps")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                
                Spacer()
                
                Image("planningIllustration") // Ensure this asset exists in Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                
                Spacer()
                
                // Replace NavigationLink with this button:
                Button {
                    navigateToUsageScreen = true // New @State variable
                } label: {
                    Text("Start Planning")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .fullScreenCover(isPresented: $navigateToUsageScreen) {
                    UsageScreen(userId: userId) // Opens in a new modal context
                        .navigationBarHidden(true) // Ensures no toolbar appears
                }
            }
            .padding()
            
        }
    }
}

// 🔥 SwiftUI Preview
#Preview {
    StartPlanningScreen(userId: "sampleUserId123") // Example User ID for preview
}
