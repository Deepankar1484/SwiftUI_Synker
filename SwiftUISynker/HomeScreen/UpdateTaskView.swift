import SwiftUI
import FirebaseFirestore

struct UpdateTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isUpdated: Bool
    @Binding var task: UserTask
    @State private var showValidationAlert = false
    @State private var showConfirmationAlert = false
    @State private var alertMessage = ""
    @State private var isUpdating = false
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var editedTask: UserTask
    @State private var startTime: Date
    @State private var endTime: Date
    
    private let db = Firestore.firestore()
    
    init(isUpdated: Binding<Bool>, task: Binding<UserTask>) {
        self._isUpdated = isUpdated
        self._task = task
        self._editedTask = State(initialValue: task.wrappedValue)
        self._startTime = State(initialValue: Date.fromTimeString(task.wrappedValue.startTime) ?? Date())
        self._endTime = State(initialValue: Date.fromTimeString(task.wrappedValue.endTime) ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
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

                Section(header: Text("Date & Time")) {
                    DatePicker("Select Date",
                             selection: $editedTask.date,
                             in: Date()..., // Prevent past dates
                             displayedComponents: .date)
                    
                    DatePicker("Start Time",
                             selection: $startTime,
                             displayedComponents: .hourAndMinute)
                        .onChange(of: startTime) { newValue in
                            // Prevent selecting start time earlier than current time if it's today
                            if Calendar.current.isDate(editedTask.date, inSameDayAs: Date()) {
                                let currentTime = Date()
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.hour, .minute], from: newValue)
                                let currentComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
                                
                                if (components.hour! < currentComponents.hour!) ||
                                   (components.hour == currentComponents.hour && components.minute! < currentComponents.minute!) {
                                    startTime = currentTime
                                    alertMessage = "Start time cannot be earlier than current time for today's tasks."
                                    showValidationAlert = true
                                }
                            }
                            
                            // Ensure end time is always after start time
                            if endTime <= startTime {
                                endTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime) ?? startTime
                            }
                        }
                    
                    DatePicker("End Time",
                             selection: $endTime,
                             displayedComponents: .hourAndMinute)
                        .onChange(of: endTime) { newValue in
                            if newValue <= startTime {
                                endTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime) ?? startTime
                                alertMessage = "End time must be after start time."
                                showValidationAlert = true
                            }
                        }
                }

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

                Section {
                    if isUpdating {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Updating...")
                            Spacer()
                        }
                    } else {
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
                Button("Update", action: updateTaskInFirebase)
            } message: {
                Text("Are you sure you want to update this task?")
            }
        }
    }

    private func validateAndShowConfirmation() {
        // Validate task name
        if editedTask.taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMessage = "Please enter a task name."
            showValidationAlert = true
            return
        }
        
        // Validate description
        if editedTask.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMessage = "Please enter a task description."
            showValidationAlert = true
            return
        }
        
        // Validate time
        if startTime >= endTime {
            alertMessage = "End time must be after start time."
            showValidationAlert = true
            return
        }
        
        // Validate date is not earlier than current date
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: editedTask.date)
        
        if selectedDay < today {
            alertMessage = "Cannot update tasks to past dates."
            showValidationAlert = true
            return
        }
        
        // Validate time is not earlier than current time if it's today
        if selectedDay == today {
            let currentTime = Date()
            let currentComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
            let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
            
            // Compare hours and minutes
            if (startComponents.hour! < currentComponents.hour!) ||
               (startComponents.hour == currentComponents.hour && startComponents.minute! < currentComponents.minute!) {
                alertMessage = "Start time cannot be earlier than current time for today's tasks."
                showValidationAlert = true
                return
            }
        }
        
        showConfirmationAlert = true
    }

    private func updateTaskInFirebase() {
        isUpdating = true
        
        // Convert Date values back to Strings
        editedTask.startTime = startTime.timeString()
        editedTask.endTime = endTime.timeString()
        
        // Prepare the data to update
        let taskData: [String: Any] = [
            "id": task.id.uuidString,
            "taskName": editedTask.taskName,
            "description": editedTask.description,
            "startTime": editedTask.startTime,
            "endTime": editedTask.endTime,
            "date": Timestamp(date: editedTask.date),
            "priority": editedTask.priority.rawValue,
            "alert": editedTask.alert.rawValue,
            "category": editedTask.category.rawValue,
            "otherCategory": editedTask.otherCategory ?? "",
            "isCompleted": editedTask.isCompleted
        ]
        
        if editedTask.alert != .none {
            // Schedule notification
            self.notificationManager.scheduleTaskNotification(task: editedTask)
        }
        
        // Update the task in Firestore
        db.collection("tasks")
            .whereField("id", isEqualTo: task.id.uuidString)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("❌ Error finding task: \(error)")
                    isUpdating = false
                    alertMessage = "Failed to update task. Please try again."
                    showValidationAlert = true
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    print("❌ Task not found")
                    isUpdating = false
                    alertMessage = "Task not found in database."
                    showValidationAlert = true
                    return
                }
                
                document.reference.updateData(taskData) { error in
                    isUpdating = false
                    
                    if let error = error {
                        print("❌ Error updating task: \(error)")
                        alertMessage = "Failed to update task. Please try again."
                        showValidationAlert = true
                        return
                    }
                    
                    print("✅ Task updated successfully")
                    
                    // Update local task and dismiss
                    task = editedTask
                    isUpdated = true
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
}

// Helper extensions
extension Date {
    static func fromTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: timeString)
    }
    
    
}
