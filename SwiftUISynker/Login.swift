import SwiftUI

struct AuthenticationView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var showLogin = true
    @State private var loggedUser: User?

    var body: some View {
        if isLoggedIn, let user = loggedUser {
            CustomTabBar(loggedUser: user) // Navigate to Main App after login
        } else {
            if showLogin {
                LoginView(toggleView: { showLogin = false }, onLoginSuccess: { user in
                    loggedUser = user
                    isLoggedIn = true // Set logged in state
                })
            } else {
                SignupView(toggleView: { showLogin = true })
            }
        }
    }
}

struct LoginView: View {
    var toggleView: () -> Void
    var onLoginSuccess: (User) -> Void  // Callback for successful login

    @State private var email = "a@gmail.com"
    @State private var password = "123456"
    @State private var errorMessage: String? = nil

    var body: some View {
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

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: handleLogin) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Text("or continue with")
                .foregroundColor(.gray)

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
    }

    func handleLogin() {
        if !validateEmail(email) {
            errorMessage = "Invalid email format."
            return
        }
        if !validatePassword(password) {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        let taskDataModel = TaskDataModel.shared
        if let user = taskDataModel.validateUser(email: email, password: password) {
            print("Login successful!")
            errorMessage = nil
            onLoginSuccess(user)  // Notify AuthenticationView of successful login
        } else {
            errorMessage = "Invalid credentials. Please try again."
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


// Preview
#Preview {
    AuthenticationView()
}
