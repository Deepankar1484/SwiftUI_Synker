import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthenticationView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var showLogin = true
    @State private var loggedUser: User?
    

    var body: some View {
        if isLoggedIn, let user = loggedUser {
            CustomTabBar(loggedUser: user) // Navigate to main app screen
        } else {
            if showLogin {
                LoginView(toggleView: { showLogin = false }, onLoginSuccess: { user in
                    loggedUser = user
                    isLoggedIn = true
                })
            } else {
                SignupView(toggleView: { showLogin = true })
            }
        }
    }
}


    
    struct LoginView: View {
        var toggleView: () -> Void
        var onLoginSuccess: (User) -> Void
        
        @State private var email = ""
        @State private var password = ""
        @State private var errorMessage: String? = nil
        @State private var isLoading = false
        @State private var showForgotPasswordSheet = false

        
        var body: some View {
            ZStack {
                VStack(spacing: 15) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                    
                    Text("Log in to your account")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top, -10)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.horizontal)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    Button("Forgot Password?") {
                        showForgotPasswordSheet = true
                    }
                    .foregroundColor(.blue)
                    .font(.caption)
                    .padding(.horizontal)
                    .sheet(isPresented: $showForgotPasswordSheet) {
                        ForgotPasswordEmailView()
                    }

                   
                    
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: handleLogin) {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(isLoading)
                    
                    
                    Spacer()
                    
                    HStack {
                        Text("Don't have an account?")
                        Button("Sign up") {
                            toggleView()
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                    }
                    .padding(.bottom, 20)
                }
                .padding()
                
                // 🔥 Improved Loading Overlay 🔥
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4) // Semi-transparent background
                            .ignoresSafeArea()
                        
                        VStack(spacing: 10) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5) // Bigger spinner
                            Text("Signing in...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .frame(width: 150, height: 120)
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(15)
                    }
                }
            }
        }
        
        func handleLogin() {
            guard validateEmail(email) else {
                errorMessage = "Invalid email format."
                return
            }
            guard validatePassword(password) else {
                errorMessage = "Password must be at least 6 characters."
                return
            }
            
            isLoading = true
            errorMessage = nil  // Clear previous errors
            
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                DispatchQueue.main.async {
                    isLoading = false
                }
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let userId = result?.user.uid else {
                    errorMessage = "User ID not found."
                    return
                }
                
                fetchUserDetails(userId: userId)
            }
        }
        
        func fetchUserDetails(userId: String) {
            let db = Firestore.firestore()
            
            db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to fetch user details: \(error.localizedDescription)"
                    return
                }
                
                guard let data = snapshot?.data() else {
                    errorMessage = "No user data found."
                    return
                }
                
                let name = data["name"] as? String ?? "Unknown"
                let email = data["email"] as? String ?? ""
                let password = data["password"] as? String ?? "" // Ensure it's stored in Firestore
                let phone = data["phone"] as? String
                
                DispatchQueue.main.async {
                    let user = User(name: name, email: email, password: password) // Use existing init
                    onLoginSuccess(user)
                }
            }
        }
        
        func validateEmail(_ email: String) -> Bool {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
        }
        
        func validatePassword(_ password: String) -> Bool {
            return password.count >= 6
        }
    }

#Preview {
    AuthenticationView()
}
