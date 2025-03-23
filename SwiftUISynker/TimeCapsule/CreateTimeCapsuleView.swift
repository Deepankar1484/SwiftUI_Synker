import SwiftUI

struct CreateTimeCapsuleView: View {
    @Environment(\.presentationMode) var presentationMode // For dismissing the view
    @Binding var isUpdated: Bool
    @State private var capsuleName: String = ""
    @State private var capsuleDescription: String = ""
    @State private var deadline: Date = Date()
    @State private var priority: Priority = .low
    @State private var subtasks: [Subtask] = []
    @State private var newSubtaskName: String = ""
    @State private var newSubtaskDescription: String = ""
    @State private var showAlert: Bool = false // State to control the alert
    var loggedUser: User?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Time Capsule Details")) {
                    TextField("Project Name", text: $capsuleName)
                    TextField("Description", text: $capsuleDescription)
                }

                Section(header: Text("Deadline & Priority")) {
                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
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
                            if !newSubtaskName.isEmpty {
                                let newSubtask = Subtask(subtaskName: newSubtaskName, description: newSubtaskDescription)
                                subtasks.append(newSubtask)
                                newSubtaskName = ""
                                newSubtaskDescription = ""
                            }
                        }
                    }
                }

                Button(action: {
                    showAlert = true // Show alert when button is pressed
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
