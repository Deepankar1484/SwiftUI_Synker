import SwiftUI
import FirebaseFirestore

struct CreateTimeCapsuleView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isUpdated: Bool

    @State private var capsuleName: String = ""
    @State private var capsuleDescription: String = ""
    @State private var deadline: Date = Date().addingTimeInterval(86400)
    @State private var priority: Priority = .low

    @State private var subtasks: [Subtask] = []
    @State private var newSubtaskName: String = ""
    @State private var newSubtaskDescription: String = ""

    @State private var showAlert: Bool = false
    @State private var validationError: String?
    var loggedUser: User?

    @State private var savedSubtaskIds: Set<UUID> = []

    private let db = Firestore.firestore()

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
                        ForEach(Priority.allCases, id: \.self) {
                            Text($0.rawValue.capitalized)
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
                                let subtask = subtasks[index]
                                let subtaskId = subtask.subtaskId

                                if savedSubtaskIds.contains(subtaskId) {
                                    db.collection("subtasks").document(subtaskId.uuidString).delete { error in
                                        if let error = error {
                                            print("Error deleting subtask: \(error.localizedDescription)")
                                        } else {
                                            print("Subtask deleted from Firebase")
                                        }
                                    }
                                    savedSubtaskIds.remove(subtaskId)
                                }

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
                            let name = newSubtaskName.trimmingCharacters(in: .whitespacesAndNewlines)
                            let desc = newSubtaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)

                            if !name.isEmpty && !desc.isEmpty {
                                let subtask = Subtask(subtaskName: name, description: desc)
                                subtasks.append(subtask)
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
                        showAlert = true
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
                    Button("Save") {
                        saveTimeCapsule()
                    }
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

    func validateInputs() -> Bool {
        if capsuleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Project name is required."
            return false
        }

        if capsuleDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Description is required."
            return false
        }

        if deadline <= Date() {
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
        let capsuleId = UUID()
        var subtaskIds: [UUID] = []

        let dispatchGroup = DispatchGroup()

        for subtask in subtasks {
            dispatchGroup.enter()

            let id = subtask.subtaskId
            subtaskIds.append(id)

            let data: [String: Any] = [
                "id": id.uuidString,
                "subtaskName": subtask.subtaskName,
                "description": subtask.description,
                "isCompleted": subtask.isCompleted
            ]

            db.collection("subtasks").document(id.uuidString).setData(data) { error in
                if let error = error {
                    print("Failed to save subtask \(id): \(error.localizedDescription)")
                } else {
                    savedSubtaskIds.insert(id)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main, execute: {
            var capsule = TimeCapsule(
                capsuleName: capsuleName,
                deadline: deadline,
                priority: priority,
                description: capsuleDescription,
                category: .work
            )
            
            capsule.id=capsuleId
            capsule.subtaskIds=subtaskIds
            capsule.completionPercentage=0

            let capsuleData: [String: Any] = [
                "id": capsuleId.uuidString,
                "capsuleName": capsule.capsuleName,
                "deadline": Timestamp(date: capsule.deadline),
                "priority": capsule.priority.rawValue,
                "description": capsule.description,
                "category": capsule.category.rawValue,
                "subtaskIds": capsule.subtaskIds.map { $0.uuidString },
                "completionPercentage": capsule.completionPercentage
            ]

            db.collection("timeCapsules").document(capsuleId.uuidString).setData(capsuleData) { error in
                if let error = error {
                    print("Failed to save time capsule: \(error.localizedDescription)")
                    return
                }

                guard let email = loggedUser?.email else { return }

                db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                    if let error = error {
                        print("Error finding user: \(error.localizedDescription)")
                        return
                    }

                    guard let doc = snapshot?.documents.first else { return }

                    db.collection("users").document(doc.documentID).updateData([
                        "timeCapsuleIds": FieldValue.arrayUnion([capsuleId.uuidString])
                    ]) { error in
                        if let error = error {
                            print("Failed to update user document: \(error.localizedDescription)")
                        } else {
                            isUpdated = true
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        })
    }
}
