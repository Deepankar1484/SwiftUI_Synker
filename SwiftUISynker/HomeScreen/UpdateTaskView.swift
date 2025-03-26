import SwiftUI

struct UpdateTaskView: View {
    @Environment(\.presentationMode) var presentationMode // For dismissing the view
    @Binding var isUpdated: Bool
    @Binding var task: UserTask
    @State private var showValidationAlert = false
    @State private var showConfirmationAlert = false
    @State private var alertMessage = ""

    // Temporary copy for editing
    @State private var editedTask: UserTask
    @State private var startTime: Date
    @State private var endTime: Date

    init(isUpdated: Binding<Bool>, task: Binding<UserTask>) {
        self._isUpdated = isUpdated
        self._task = task

        // Initialize temporary task copy
        self._editedTask = State(initialValue: task.wrappedValue)

        // Convert string times to Date format
        self._startTime = State(initialValue: Date.fromTimeString(task.wrappedValue.startTime) ?? Date())
        self._endTime = State(initialValue: Date.fromTimeString(task.wrappedValue.endTime) ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
                // Section 1: Name & Description
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $editedTask.taskName)
                        .frame(minHeight: 40)
                    ZStack(alignment: .topLeading) {
                        if editedTask.description.isEmpty {
                            Text("Description")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.horizontal, 1)
                                .padding(.vertical, 12)
                        }
                        TextEditor(text: $editedTask.description)
                    }
                }

                // Section 2: Date & Time
                Section(header: Text("Date & Time")) {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    DatePicker("Select Date", selection: $editedTask.date, displayedComponents: .date)
                }

                // Section 3: Priority, Alert & Category
                Section(header: Text("Additional Options")) {
                    Picker("Priority", selection: $editedTask.priority) {
                        ForEach(Priority.allCases, id: \.self) { Text($0.rawValue) }
                    }

                    Picker("Alert", selection: $editedTask.alert) {
                        ForEach(Alert.allCases, id: \.self) { Text($0.rawValue) }
                    }

                    Picker("Category", selection: $editedTask.category) {
                        ForEach(Category.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }

                // Save Button
                Section {
                    Button(action: validateAndShowConfirmation) {
                        Text("Update Task")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Update Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert("Invalid Input", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert("Confirm Update", isPresented: $showConfirmationAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Update", action: updateTaskAndDismiss)
            } message: {
                Text("Are you sure you want to update this task?")
            }
        }
    }

    private func validateAndShowConfirmation() {
        if editedTask.taskName.isEmpty || editedTask.description.isEmpty {
            alertMessage = "Task Name and Description cannot be empty."
            showValidationAlert = true
            return
        }

        if startTime >= endTime {
            alertMessage = "Start Time cannot be later than or equal to End Time."
            showValidationAlert = true
            return
        }

        let today = Calendar.current.startOfDay(for: Date())
        let selectedDay = Calendar.current.startOfDay(for: editedTask.date)
        if selectedDay < today {
            alertMessage = "You cannot update a task for a past date."
            showValidationAlert = true
            return
        }

        // If validation passes, show confirmation alert
        showConfirmationAlert = true
    }

    private func updateTaskAndDismiss() {
        // Convert Date values back to Strings
        editedTask.startTime = startTime.timeString()
        editedTask.endTime = endTime.timeString()

        // Update the actual task after confirmation
        task = editedTask

        // Get the shared TaskDataModel instance
        let taskModel = TaskDataModel.shared
        taskModel.updateTask(task)

        isUpdated = true
        presentationMode.wrappedValue.dismiss()
    }
}
