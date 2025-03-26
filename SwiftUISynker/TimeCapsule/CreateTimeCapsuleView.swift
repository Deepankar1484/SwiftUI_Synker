import SwiftUI

struct CreateTimeCapsuleView: View {
    @Environment(\.presentationMode) var presentationMode // For dismissing the view
    @Binding var isUpdated: Bool
    @State private var capsuleName: String = ""
    @State private var capsuleDescription: String = ""
    @State private var deadline: Date = Date().addingTimeInterval(86400)
    @State private var priority: Priority = .low
    @State private var subtasks: [Subtask] = []
    @State private var newSubtaskName: String = ""
    @State private var newSubtaskDescription: String = ""
    @State private var showAlert: Bool = false // Alert for save confirmation
    @State private var validationError: String? // State to hold validation messages
    var loggedUser: User?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Time Capsule Details")) {
                    TextField("Project Name", text: $capsuleName)
                    TextField("Description", text: $capsuleDescription)
                }

                Section(header: Text("Deadline & Priority")) {
                    DatePicker("Deadline", selection: $deadline, in: Date().addingTimeInterval(86400)..., displayedComponents: .date)
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section(header: Text("Subtasks: \(subtasks.count)")) {
                    ForEach(subtasks.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(subtasks[index].subtaskName).bold()
                                Text(subtasks[index].description).font(.subheadline).foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                subtasks.remove(at: index)
                            }) {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        }
                    }

                    HStack {
                        VStack {
                            TextField("Subtask Name", text: $newSubtaskName)
                            Divider()
                            TextField("Subtask Description", text: $newSubtaskDescription)
                        }
                        
                        Button("Add") {
                            let trimmedName = newSubtaskName.trimmingCharacters(in: .whitespacesAndNewlines)
                            let trimmedDescription = newSubtaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)

                            if !trimmedName.isEmpty && !trimmedDescription.isEmpty {
                                let newSubtask = Subtask(subtaskName: trimmedName, description: trimmedDescription)
                                subtasks.append(newSubtask)
                                newSubtaskName = ""
                                newSubtaskDescription = ""
                            }
                        }
                        .disabled(newSubtaskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  newSubtaskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                if let error = validationError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }

                Button(action: {
                    if validateInputs() {
                        showAlert = true // Show confirmation alert
                    }
                }) {
                    Text("Add Time Capsule")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .alert("Save Time Capsule?", isPresented: $showAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Save", role: .none) { saveTimeCapsule() }
                } message: {
                    Text("Are you sure you want to save this Time Capsule?")
                }
            }
            .navigationTitle("Time Capsule")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    // MARK: - Validation Function
    func validateInputs() -> Bool {
        if capsuleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Project name is required."
            return false
        }

        if capsuleDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Description is required."
            return false
        }

        if deadline <= Date() { // Ensuring date is at least tomorrow
            validationError = "Deadline must be in the future."
            return false
        }

        if subtasks.isEmpty {
            validationError = "At least one subtask must be added."
            return false
        }

        validationError = nil
        return true
    }

    func saveTimeCapsule() {
        let newCapsule = TimeCapsule(
            capsuleName: capsuleName,
            deadline: deadline,
            priority: priority,
            description: capsuleDescription,
            category: .work
        )
        let taskModel = TaskDataModel.shared
        if let user = loggedUser {
            let _ = taskModel.addTimeCapsule(newCapsule, for: user.userId)
        }
        for subtask in subtasks {
            let _ = taskModel.addSubtask(subtask, to: newCapsule.id)
        }
        isUpdated = true
        presentationMode.wrappedValue.dismiss() // Dismiss view after saving
    }
}
