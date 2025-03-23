import SwiftUI

struct CreateTaskView: View {
    @Environment(\.presentationMode) var presentationMode // For dismissing the view
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
                
                // Section 2: Date & Time
                Section(header: Text("Date & Time")) {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    DatePicker("Select Date", selection: $taskDate, displayedComponents: .date)
                }
                
                // Section 3: Priority, Alert & Category
                Section(header: Text("Additional Options")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    
                    Picker("Alert", selection: $alert) {
                        ForEach(Alert.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { Text($0.rawValue) }
                    }
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
        }
    }
    
    private func validateAndShowConfirmation() {
        // 1. Check if any field is empty
        if taskName.isEmpty || taskDescription.isEmpty {
            alertMessage = "Task Name and Description cannot be empty."
            showValidationAlert = true
            return
        }

        // 2. Check if Start Time is later than End Time on the same day
        if startTime >= endTime {
            alertMessage = "Start Time cannot be later than or Equal to End Time."
            showValidationAlert = true
            return
        }
        
        // 3. Check if selected date is in the past
        let today = Calendar.current.startOfDay(for: Date()) // Get only the date part
        let selectedDay = Calendar.current.startOfDay(for: taskDate)
        if selectedDay < today {
            alertMessage = "You cannot create a task for a past date."
            showValidationAlert = true
            return
        }

        // If validation passes, show confirmation alert
        showConfirmationAlert = true
    }
    
    private func saveTaskAndDismiss() {
        let tempTask = UserTask(taskName: taskName, description: taskDescription, startTime: startTime.timeString(), endTime: endTime.timeString(), date: taskDate, priority: priority, alert: alert, category: category)
        let taskModel = TaskDataModel.shared
        if let user = loggedUser {
            let checkTask = taskModel.addTask(tempTask, for: user.userId)
            if checkTask {
                // Dismiss the view after saving
                isUpdated = true
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

//struct CreateTaskView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreateTaskView()
//    }
//}
