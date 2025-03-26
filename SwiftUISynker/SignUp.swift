import SwiftUI

struct SignupView: View {
    var toggleView: () -> Void
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var navigateToStartPlanning = false  // State to track navigation
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                // App Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                
                // Short text under the logo
                Text("Create your new account")
                    .font(.headline)
                    .foregroundColor(.gray)

                // Full Name Field
                TextField("Full Name", text: $fullName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // Email Field
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal)

                // Password Field
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                // Signup Button
                Button(action: {
                    print("Signup Button Tapped")
                    navigateToStartPlanning = true // Trigger navigation
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(fullName.isEmpty || email.isEmpty || password.isEmpty)
                .padding(.horizontal)
                
                Text("or continue with")
                    .foregroundColor(.gray)
                
                // Continue with Google Button
                Button(action: {
                    print("Continue with Google")
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.red)
                        Text("Continue with Google")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
                
                // Login Link
                HStack {
                    Text("Already have an account?")
                    Button("Log in") {
                        toggleView()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
                }
                .padding(.bottom, 20)
                
                // Navigation trigger (hidden but activates on state change)
                NavigationLink(
                    destination: StartPlanningScreen(),
                    isActive: $navigateToStartPlanning
                ) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
}

#Preview {
    SignupView(toggleView: {})
}
