import SwiftUI
import FirebaseFirestore

extension String {
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // same format as timeString()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: self)
    }
}
extension Date {
    static func fromTimeString(_ timeString: String, on date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a" // same as .timeString()
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            return calendar.date(
                bySettingHour: calendar.component(.hour, from: time),
                minute: calendar.component(.minute, from: time),
                second: 0,
                of: date
            )
        }
        return nil
    }
}


import SwiftUI
import FirebaseFirestore

struct CreateTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isUpdated: Bool
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var taskDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var priority: Priority = .medium
    @State private var alert: Alert = .none
    @State private var category: Category = .work
    @State private var showValidationAlert = false
    @State private var showConfirmationAlert = false
    @State private var alertMessage = ""
    @State var loggedUser: User?
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    // Computed properties for validation
    private var isToday: Bool {
        Calendar.current.isDate(taskDate, inSameDayAs: Date())
    }
    
    private var currentTime: Date {
        Date()
    }
    
    private var currentTimeComponents: DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: currentTime)
    }

    var body: some View {
        NavigationView {
            Form {
                // Section 1: Name & Description
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $taskName)
                        .frame(minHeight: 40)
                    ZStack(alignment: .topLeading) {
                        if taskDescription.isEmpty {
                            Text("Description")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .padding(.horizontal, 1)
                                .padding(.vertical, 12)
                        }
                        TextEditor(text: $taskDescription)
                    }
                }
                
                // Section 2: Date & Time with validations
                Section(header: Text("Date & Time")) {
                    DatePicker("Select Date",
                             selection: $taskDate,
                             in: Date()..., // Prevent past dates
                             displayedComponents: .date)
                    
                    DatePicker("Start Time",
                             selection: $startTime,
                             displayedComponents: .hourAndMinute)
                        .onChange(of: startTime) { newValue in
                            if isToday {
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.hour, .minute], from: newValue)
                                
                                // If selected time is before current time, adjust to current time
                                if let hour = components.hour, let minute = components.minute,
                                   hour < currentTimeComponents.hour! ||
                                   (hour == currentTimeComponents.hour! && minute < currentTimeComponents.minute!) {
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
                
                // Section 3: Priority, Alert & Category
                Section(header: Text("Additional Options")) {
                    Picker("Alert", selection: $alert) {
                        ForEach(Alert.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    
                    HStack {
                        Text("Priority")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 15) {
                            ForEach(Priority.allCases, id: \.self) { level in
                                Image(systemName: "flag.circle.fill")
                                    .resizable()
                                    .frame(width: priority == level ? 40 : 30,
                                           height: priority == level ? 40 : 30)
                                    .foregroundColor(Color(level.tintColor))
                                    .opacity(priority == level ? 1 : 0.5)
                                    .onTapGesture {
                                        priority = level
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical, 5)
                }
                
                // Save Button
                Section {
                    Button(action: validateAndShowConfirmation) {
                        Text("Save Task")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert("Invalid Input", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert("Confirm Save", isPresented: $showConfirmationAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Save", action: saveTaskAndDismiss)
            } message: {
                Text("Are you sure you want to save this task?")
            }
            .onAppear {
                // Initialize times to current time if today is selected
                if isToday {
                    startTime = currentTime
                    endTime = Calendar.current.date(byAdding: .minute, value: 30, to: currentTime) ?? currentTime
                }
            }
        }
    }
    
    private func validateAndShowConfirmation() {
        // 1. Validate empty fields
        guard !taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a task name."
            showValidationAlert = true
            return
        }
        
        guard !taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a task description."
            showValidationAlert = true
            return
        }
        
        // 2. Validate time ranges
        guard startTime < endTime else {
            alertMessage = "End time must be after start time."
            showValidationAlert = true
            return
        }
        
        // 3. Validate current day/time
        if isToday {
            let calendar = Calendar.current
            let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
            
            if startComponents.hour! < currentTimeComponents.hour! ||
               (startComponents.hour == currentTimeComponents.hour && startComponents.minute! < currentTimeComponents.minute!) {
                alertMessage = "Start time cannot be earlier than current time for today's tasks."
                showValidationAlert = true
                return
            }
        }
        
        // 4. Check for overlapping tasks
        checkForOverlappingTasks { hasOverlap in
            if hasOverlap {
                // Show overlap alert
                alertMessage = "This time slot overlaps with another task. Please choose a different time."
                showValidationAlert = true
            } else {
                // No overlap, show confirmation
                showConfirmationAlert = true
            }
        }
    }

    private func checkForOverlappingTasks(completion: @escaping (Bool) -> Void) {
        guard let user = loggedUser else {
            alertMessage = "User not logged in."
            showValidationAlert = true
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let calendar = Calendar.current
        
        // Get start and end of the selected date
        let startOfDay = calendar.startOfDay(for: taskDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Query tasks for the current user on the selected date
        db.collection("tasks")
            .whereField("userEmail", isEqualTo: user.email)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching tasks: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(false)
                    return
                }
                
                // Convert new task times to minutes since midnight for easier comparison
                let newStartMinutes = calendar.component(.hour, from: startTime) * 60 + calendar.component(.minute, from: startTime)
                let newEndMinutes = calendar.component(.hour, from: endTime) * 60 + calendar.component(.minute, from: endTime)
                
                // Check each existing task for overlap
                for document in documents {
                    let data = document.data()
                    
                    guard let existingStartTimeString = data["startTime"] as? String,
                          let existingEndTimeString = data["endTime"] as? String,
                          let existingStartTime = existingStartTimeString.toDate(),
                          let existingEndTime = existingEndTimeString.toDate() else {
                        continue
                    }
                    
                    // Convert existing task times to minutes since midnight
                    let existingStartMinutes = calendar.component(.hour, from: existingStartTime) * 60 +
                                             calendar.component(.minute, from: existingStartTime)
                    let existingEndMinutes = calendar.component(.hour, from: existingEndTime) * 60 +
                                           calendar.component(.minute, from: existingEndTime)
                    
                    // Check for overlap (simplified logic)
                    let isOverlapping = (newStartMinutes < existingEndMinutes) && (newEndMinutes > existingStartMinutes)
                    
                    if isOverlapping {
                        completion(true)
                        return
                    }
                }
                
                // No overlaps found
                completion(false)
            }
    }
    
    private func saveTaskAndDismiss() {
        guard let user = loggedUser else {
            alertMessage = "User not logged in."
            showValidationAlert = true
            return
        }

        let taskId = UUID().uuidString
        let db = Firestore.firestore()

        let taskData: [String: Any] = [
            "id": taskId,
            "taskName": taskName,
            "description": taskDescription,
            "startTime": startTime.timeString(),
            "endTime": endTime.timeString(),
            "date": Timestamp(date: taskDate),
            "priority": priority.rawValue,
            "alert": alert.rawValue,
            "category": category.rawValue,
            "isCompleted": false,
            "userEmail": user.email
        ]

        db.collection("tasks").document(taskId).setData(taskData) { error in
            if let error = error {
                alertMessage = "Error saving task: \(error.localizedDescription)"
                showValidationAlert = true
                return
            }

            // Update user's taskIds
            let usersRef = db.collection("users").whereField("email", isEqualTo: user.email)
            usersRef.getDocuments { snapshot, error in
                if let error = error {
                    alertMessage = "Error finding user: \(error.localizedDescription)"
                    showValidationAlert = true
                    return
                }
                
                if self.alert != .none {
                    let newTask = UserTask(
                        taskName: self.taskName,
                        description: self.taskDescription,
                        startTime: self.startTime.timeString(),
                        endTime: self.endTime.timeString(),
                        date: self.taskDate,
                        priority: self.priority,
                        alert: self.alert,
                        category: self.category
                    )
                    
                    // Schedule notification
                    self.notificationManager.scheduleTaskNotification(task: newTask)
                }

                guard let doc = snapshot?.documents.first else {
                    alertMessage = "User not found."
                    showValidationAlert = true
                    return
                }

                doc.reference.updateData([
                    "taskIds": FieldValue.arrayUnion([taskId])
                ]) { error in
                    if let error = error {
                        alertMessage = "Error updating user tasks: \(error.localizedDescription)"
                        showValidationAlert = true
                        return
                    }

                    isUpdated = true
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
extension Date {
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }
}
