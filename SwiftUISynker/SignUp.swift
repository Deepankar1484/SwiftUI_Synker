import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignupView: View {
    var toggleView: () -> Void
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var navigateToStartPlanning = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var userId: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                
                Text("Create your new account")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                TextField("Full Name", text: $fullName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
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
                        .padding()
                }
                
                Button(action: signup) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(fullName.isEmpty || email.isEmpty || password.isEmpty || isLoading)
                .padding(.horizontal)
                
                
                
                
                Spacer()
                
                HStack {
                    Text("Already have an account?")
                    Button("Log in") {
                        toggleView()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
                }
                .padding(.bottom, 20)
                
                .fullScreenCover(isPresented: $navigateToStartPlanning) {
                    StartPlanningScreen(userId: userId ?? "")
                        .navigationBarHidden(true) // Ensure no navigation bar appears
                }
            }
            .padding()
            
        }
    }
    
    func signup() {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }
            
            guard let authUser = authResult?.user else {
                errorMessage = "Failed to get user info"
                isLoading = false
                return
            }
            
            let userId = authUser.uid
            // Create the welcome award
            let welcomeAward = AwardsEarned(
                awardName: "Welcome Aboard!",
                description: "Congratulations on joining our community. Your journey begins now!",
                awardImage: "🏆",
                dateEarned: Date()
            )

            // Convert the AwardsEarned struct to a dictionary
            let welcomeAwardDict: [String: Any] = [
                "id": welcomeAward.id.uuidString,
                "awardName": welcomeAward.awardName,
                "description": welcomeAward.description,
                "awardImage": welcomeAward.awardImage,
                "dateEarned": Timestamp(date: welcomeAward.dateEarned)
            ]

            // Create the user data with the award dictionary
            let userData: [String: Any] = [
                "userId": userId,
                "name": fullName,
                "email": email,
                "taskIds": [],
                "timeCapsuleIds": [],
                "totalStreak": 0,
                "maxStreak": 0,
                "settings": [
                    "notificationsEnabled": true
                ],
                "awardsEarned": [welcomeAwardDict],
                "lastDateModified": Timestamp(date: Date())
            ]
            
            Firestore.firestore().collection("users").document(userId).setData(userData) { error in
                isLoading = false
                if let error = error {
                    errorMessage = "Firestore Error: \(error.localizedDescription)"
                } else {
                    self.userId = userId
                    self.navigateToStartPlanning = true
                }
            }
        }
    }
}

#Preview {
    SignupView(toggleView: {})
}
