import SwiftUI

struct StartPlanningScreen: View {
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
                
                NavigationLink(destination: UsageScreen()) {
                    Text("Start Planning")
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
    }
}

#Preview {
    StartPlanningScreen()
}
