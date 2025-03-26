import SwiftUI

struct EditProfileView: View {
    @Binding var user: User
    
    @State private var editedUser: User // Temporary user copy
    @State private var showConfirmationAlert = false
    
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

                    TextField("Phone", text: $editedUser.phone)
                        .keyboardType(.phonePad)

                    TextField("Email", text: .constant(user.email)) // Email is non-editable
                        .disabled(true)
                        .foregroundColor(.gray)
                }

                Section(header: Text("Preferences")) {
                    Picker("Usage Type", selection: $editedUser.settings.usage) {
                        ForEach(Usage.allCases, id: \.self) { usage in
                            Text(usage.rawValue).tag(usage)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Toggle("Enable Notifications", isOn: $editedUser.settings.notificationsEnabled)

                    DatePicker("Bedtime", selection: Binding(
                        get: { Date.fromTimeString(editedUser.settings.bedtime) ?? Date() },
                        set: { editedUser.settings.bedtime = $0.timeString() }
                    ), displayedComponents: .hourAndMinute)

                    DatePicker("Wake Up Time", selection: Binding(
                        get: { Date.fromTimeString(editedUser.settings.wakeUpTime) ?? Date() },
                        set: { editedUser.settings.wakeUpTime = $0.timeString() }
                    ), displayedComponents: .hourAndMinute)
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
        }
    }

    func saveChanges() {
        user = editedUser // Apply changes to the original user
        
        let taskModel = TaskDataModel.shared
        taskModel.updateUser(user)
        dismiss()
    }
}
