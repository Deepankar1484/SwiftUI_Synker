//
//  ProfileView.swift
//  SwiftUISynker
//
//  Created by Deepankar Garg on 25/03/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @State var loggedUser: User
    @State private var isEditing = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var showReauthAlert = false
    @State private var reauthPassword = ""
    @State private var showDeletionError = false
    @State private var deletionError = ""
    @State private var isLoading = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding(.top, 20)

                // User Info Card
                VStack(alignment: .leading, spacing: 10) {
                    ProfileRow(title: "Name", value: loggedUser.name)
                    ProfileRow(title: "Email", value: loggedUser.email)
                    ProfileRow(title: "Phone", value: loggedUser.phone ?? "Not Provided")
                    ProfileRow(title: "Notifications", value: loggedUser.settings?.notificationsEnabled == true ? "Enabled" : "Disabled")
                    ProfileRow(title: "Usage Type", value: loggedUser.settings?.usage.rawValue ?? "Not Set")
                    ProfileRow(title: "Bedtime", value: loggedUser.settings?.bedtime ?? "Not Set")
                    ProfileRow(title: "Wake Up Time", value: loggedUser.settings?.wakeUpTime ?? "Not Set")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 15).fill(Color(.systemGray6)))
                .padding(.horizontal)

                // Buttons
                VStack(spacing: 15) {
                    Button(action: { showLogoutAlert.toggle() }) {
                        Text("Logout")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: { showDeleteAlert.toggle() }) {
                        Text("Delete Account")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing.toggle()
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditProfileView(user: $loggedUser)
        }
        .alert("Confirm Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) { logout() }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Confirm Account Deletion", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { initiateAccountDeletion() }
        } message: {
            Text("This will permanently delete all your data. This action cannot be undone.")
        }
        .alert("Reauthentication Required", isPresented: $showReauthAlert) {
            SecureField("Enter your password", text: $reauthPassword)
            Button("Cancel", role: .cancel) {
                reauthPassword = ""
            }
            Button("Confirm", role: .none) {
                reauthenticateAndDelete(password: reauthPassword)
            }
        } message: {
            Text("For security, please enter your password to confirm account deletion.")
        }
        .alert("Deletion Error", isPresented: $showDeletionError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deletionError)
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
            }
        }
        .onAppear {
            fetchUserFromFirebase(email: loggedUser.email)
        }
    }

    // MARK: - Fetch User from Firebase
    private func fetchUserFromFirebase(email: String) {
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                return
            }
            guard let document = snapshot?.documents.first else {
                print("No user found with email \(email)")
                return
            }
            
            let data = document.data()
            let settingsData = data["settings"] as? [String: Any] ?? [:]
            
            let updatedSettings = Settings(
                profilePicture: settingsData["profilePicture"] as? String,
                usage: Usage(rawValue: settingsData["usage"] as? String ?? "Personal") ?? .personal,
                bedtime: settingsData["bedtime"] as? String ?? "Not Set",
                wakeUpTime: settingsData["wakeUpTime"] as? String ?? "Not Set",
                notificationsEnabled: settingsData["notificationsEnabled"] as? Bool ?? false
            )
            
            DispatchQueue.main.async {
                loggedUser.phone = data["phone"] as? String
                loggedUser.settings = updatedSettings
            }
        }
    }

    // MARK: - Logout Function
    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            deletionError = "Logout failed: \(error.localizedDescription)"
            showDeletionError = true
        }
    }

    // MARK: - Account Deletion Flow
    private func initiateAccountDeletion() {
        guard let user = Auth.auth().currentUser else {
            deletionError = "No authenticated user found"
            showDeletionError = true
            return
        }
        
        // Check when the user last authenticated
        let lastSignInDate = user.metadata.lastSignInDate ?? Date.distantPast
        let timeSinceLastAuth = Date().timeIntervalSince(lastSignInDate)
        
        // If it's been more than 5 minutes, require reauthentication
        if timeSinceLastAuth > 300 { // 5 minutes in seconds
            showReauthAlert = true
        } else {
            deleteUserData()
        }
    }
    
    private func reauthenticateAndDelete(password: String) {
        isLoading = true
        guard let user = Auth.auth().currentUser, let email = user.email else {
            deletionError = "Authentication error"
            showDeletionError = true
            isLoading = false
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                isLoading = false
                deletionError = "Authentication failed: \(error.localizedDescription)"
                showDeletionError = true
                reauthPassword = ""
                return
            }
            
            // Reauthentication successful, proceed with deletion
            deleteUserData()
        }
    }
    
    private func deleteUserData() {
        isLoading = true
        let db = Firestore.firestore()
        
        // First find the user document
        db.collection("users")
            .whereField("email", isEqualTo: loggedUser.email)
            .getDocuments { snapshot, error in
                if let error = error {
                    isLoading = false
                    deletionError = "Error finding user: \(error.localizedDescription)"
                    showDeletionError = true
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    isLoading = false
                    deletionError = "No user data found"
                    showDeletionError = true
                    return
                }
                
                // Get all the user's data
                let data = document.data()
                let taskIds = data["taskIds"] as? [String] ?? []
                let timeCapsuleIds = data["timeCapsuleIds"] as? [String] ?? []
                let awardsEarned = data["awardsEarned"] as? [String] ?? []
                
                // Create a batch for all delete operations
                let batch = db.batch()
                
                // 1. Delete all tasks
                for taskId in taskIds {
                    let taskRef = db.collection("tasks").document(taskId)
                    batch.deleteDocument(taskRef)
                }
                
                // 2. Delete all time capsules
                for capsuleId in timeCapsuleIds {
                    let capsuleRef = db.collection("timeCapsules").document(capsuleId)
                    batch.deleteDocument(capsuleRef)
                }
                
                // 3. Delete all awards
                for awardId in awardsEarned {
                    let awardRef = db.collection("awards").document(awardId)
                    batch.deleteDocument(awardRef)
                }
                
                // 4. Finally delete the user document
                let userRef = db.collection("users").document(document.documentID)
                batch.deleteDocument(userRef)
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        isLoading = false
                        deletionError = "Error deleting user data: \(error.localizedDescription)"
                        showDeletionError = true
                    } else {
                        print("Successfully deleted all user data")
                        
                        // Now delete the user from Firebase Authentication
                        Auth.auth().currentUser?.delete { error in
                            isLoading = false
                            
                            if let error = error {
                                deletionError = "Error deleting account: \(error.localizedDescription)"
                                showDeletionError = true
                            } else {
                                // Successfully deleted everything
                                isLoggedIn = false
                            }
                        }
                    }
                }
            }
    }
}

struct ProfileRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.bold)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}
