import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {
    @Binding var user: User
    @State private var editedUser: User // Temporary copy for editing
    @State private var showConfirmationAlert = false
    @State private var showPassword = false // State for password visibility
    @State private var showNotificationAlert = false // Alert for notification permissions
    
    // Add access to the notification manager
    @StateObject private var notificationManager = NotificationManager.shared

    @Environment(\.dismiss) var dismiss

    init(user: Binding<User>) {
        self._user = user
        self._editedUser = State(initialValue: user.wrappedValue)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("Name", text: $editedUser.name)
                        .autocapitalization(.words)

                    TextField("Phone", text: Binding(
                        get: { editedUser.phone ?? "" },
                        set: { editedUser.phone = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.phonePad)

                    TextField("Email", text: .constant(user.email)) // Non-editable
                        .disabled(true)
                        .foregroundColor(.gray)

                    HStack {
                        if showPassword {
                            TextField("Password", text: $editedUser.password)
                                .autocapitalization(.none) // Explicitly disable capitalization
                                .disableAutocorrection(true) // Also disable autocorrection
                                .keyboardType(.asciiCapable) // Use ASCII keyboard
                        } else {
                            SecureField("Password", text: $editedUser.password)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.asciiCapable)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section(header: Text("Preferences")) {
                    if let settings = editedUser.settings {
                        Picker("Usage Type", selection: Binding(
                            get: { settings.usage },
                            set: { editedUser.settings?.usage = $0 }
                        )) {
                            ForEach(Usage.allCases, id: \.self) { usage in
                                Text(usage.rawValue).tag(usage)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        // Modified notification toggle
                        Toggle("Enable Notifications", isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: { newValue in
                                if newValue {
                                    // Request permissions when turning on
                                    notificationManager.requestAuthorization { granted in
                                        if granted {
                                            editedUser.settings?.notificationsEnabled = true
                                            notificationManager.enableNotifications() // Enable user preference
                                        } else {
                                            // If permission denied, show alert and keep toggle off
                                            editedUser.settings?.notificationsEnabled = false
                                            notificationManager.disableNotifications() // Disable user preference
                                            showNotificationAlert = true
                                        }
                                    }
                                } else {
                                    // Simply turn off if toggling off
                                    editedUser.settings?.notificationsEnabled = false
                                    notificationManager.disableNotifications() // Disable user preference
                                }
                            }
                        ))

                        DatePicker("Bedtime", selection: Binding(
                            get: { Date.fromTimeString(settings.bedtime) ?? Date() },
                            set: { editedUser.settings?.bedtime = $0.timeString() }
                        ), displayedComponents: .hourAndMinute)

                        DatePicker("Wake Up Time", selection: Binding(
                            get: { Date.fromTimeString(settings.wakeUpTime) ?? Date() },
                            set: { editedUser.settings?.wakeUpTime = $0.timeString() }
                        ), displayedComponents: .hourAndMinute)
                    } else {
                        Text("No settings available")
                            .foregroundColor(.gray)
                    }
                }

                Section {
                    Button(action: { showConfirmationAlert = true }) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Confirm Changes", isPresented: $showConfirmationAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Save", role: .destructive) { saveChanges() }
            } message: {
                Text("Are you sure you want to save these changes?")
            }
            .alert("Notification Permissions", isPresented: $showNotificationAlert) {
                Button("OK", role: .cancel) {}
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable notifications in your device settings to receive task reminders.")
            }
            .onAppear {
                // Update UI based on current notification permission status
                notificationManager.checkAuthorizationStatus()
                if let settings = editedUser.settings {
                    // Make sure the toggle reflects the actual permission status and update user preference
                    let notificationsEnabled = settings.notificationsEnabled && notificationManager.isAuthorized
                    editedUser.settings?.notificationsEnabled = notificationsEnabled
                    
                    // Set the notification manager's user preference to match the UI state
                    if notificationsEnabled {
                        notificationManager.enableNotifications()
                    } else {
                        notificationManager.disableNotifications()
                    }
                }
            }
        }
    }

    func saveChanges() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No authenticated user.")
            return
        }

        guard !user.email.isEmpty else {
            print("User email is missing.")
            return
        }

        let db = Firestore.firestore()
        let email = user.email

        // First update password using Firebase Auth
        currentUser.updatePassword(to: editedUser.password) { error in
            if let error = error {
                print("Error updating password: \(error.localizedDescription)")
                return
            }

            print("Password updated successfully.")

            // Now update other fields in Firestore
            db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching user: \(error.localizedDescription)")
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("No user found with email: \(email)")
                    return
                }

                let userRef = db.collection("users").document(document.documentID)

                var updatedData: [String: Any] = [
                    "name": editedUser.name,
                    "lastDateModified": Timestamp(date: Date())
                ]

                if let phone = editedUser.phone {
                    updatedData["phone"] = phone
                } else {
                    updatedData["phone"] = FieldValue.delete()
                }

                if let settings = editedUser.settings {
                    updatedData["settings"] = [
                        "usage": settings.usage.rawValue,
                        "notificationsEnabled": settings.notificationsEnabled,
                        "bedtime": settings.bedtime,
                        "wakeUpTime": settings.wakeUpTime
                    ]
                    
                    // Update notification manager preference based on saved settings
                    if settings.notificationsEnabled {
                        notificationManager.enableNotifications()
                    } else {
                        notificationManager.disableNotifications()
                    }
                }

                userRef.updateData(updatedData) { error in
                    if let error = error {
                        print("Error updating Firestore user: \(error.localizedDescription)")
                    } else {
                        print("Firestore user updated successfully.")
                        user = editedUser
                        TaskDataModel.shared.updateUser(user)
                        dismiss()
                    }
                }
            }
        }
    }
}
