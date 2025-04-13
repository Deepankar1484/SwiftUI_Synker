import SwiftUI
import FirebaseFirestore

struct OverdueDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var loggedUser: User?
    @State var task: UserTask // Task details
    @State private var showEditView = false
    @State private var isUpdated = false
    @State private var showRescheduleAlert = false
    @State private var isRescheduling = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(task.category.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Image(systemName: "flag.circle")
                        .font(.system(size: 20, weight: .bold)) // Bigger & Bolder
                        .foregroundColor(Color(task.priority.tintColor))
                    Spacer()
                    
                    Text("\(task.startTime) - \(task.endTime)")
                        .font(.callout)
                }
                
                Divider()
                
                Text("**Name:**")
                    .font(.headline)
                Text(task.taskName)
                    .padding(.bottom, 10)
                    .foregroundColor(.primary)
                
                Divider()
                
                Text("**Description:**")
                    .font(.headline)
                Text(task.description)
                    .padding(.bottom, 10)
                    .foregroundColor(.primary)
                
                Divider()
                
                Text("**Scheduled Date:**")
                    .font(.headline)
                Text(task.date.fullFormattedString())
                    .padding(.bottom, 10)
                    .foregroundColor(.primary)
                
                Divider()
                
                Text("**Do you know:**")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(task.category.customCategory.insights)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
                
                if isRescheduling {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Rescheduling...")
                        Spacer()
                    }
                    .padding(.vertical)
                } else {
                    Button(action: {
                        showRescheduleAlert = true
                    }) {
                        Text("Reschedule for Today")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(8)
                    }
                    .alert("Reschedule Task", isPresented: $showRescheduleAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Reschedule") {
                            rescheduleTaskForToday()
                        }
                    } message: {
                        Text("Are you sure you want to reschedule this task for today?")
                    }
                    .padding(.bottom, 10)
                    
                    Button(action: {
                        showEditView = true
                    }) {
                        Text("Custom Reschedule")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 10)
                }
            }
            .padding()
        }
        .navigationBarTitle("Overdue Task", displayMode: .inline)
        .sheet(isPresented: $showEditView) {
            UpdateTaskView(isUpdated: $isUpdated, task: $task)
        }
        .onChange(of: isUpdated) {
            if isUpdated {
                presentationMode.wrappedValue.dismiss() // Dismiss OverdueDetailsView when task is updated
            }
        }
    }
    
    private func rescheduleTaskForToday() {
        isRescheduling = true
        
        // Get current date and time
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Set task date to today (just the date part)
        let todayStart = calendar.startOfDay(for: currentDate)
        task.date = todayStart
        
        // Add one hour to current time for the start time (or 15 min if it's late in day)
        let futureDate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        
        // Round start time to nearest 15 minutes
        let roundedMinutes = ((calendar.component(.minute, from: futureDate) + 14) / 15) * 15
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: futureDate)
        components.minute = roundedMinutes % 60
        
        // If we rounded up to the next hour
        if roundedMinutes >= 60 {
            components.hour = (components.hour ?? 0) + 1
        }
        
        let taskStart = calendar.date(from: components) ?? futureDate
        let taskEnd = calendar.date(byAdding: .minute, value: 30, to: taskStart) ?? taskStart
        
        // Format the start and end times
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        task.startTime = timeFormatter.string(from: taskStart)
        task.endTime = timeFormatter.string(from: taskEnd)
        
        // Prepare the data to update in Firebase
        let taskData: [String: Any] = [
            "id": task.id.uuidString,
            "taskName": task.taskName,
            "description": task.description,
            "startTime": task.startTime,
            "endTime": task.endTime,
            "date": Timestamp(date: task.date),
            "priority": task.priority.rawValue,
            "alert": task.alert.rawValue,
            "category": task.category.rawValue,
            "otherCategory": task.otherCategory ?? "",
            "isCompleted": task.isCompleted
        ]
        
        // Update task notification if needed
        if task.alert != .none {
            NotificationManager.shared.scheduleTaskNotification(task: task)
        }
        
        // Update the task in Firestore
        db.collection("tasks")
            .whereField("id", isEqualTo: task.id.uuidString)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("❌ Error finding task: \(error)")
                    isRescheduling = false
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    print("❌ Task not found")
                    isRescheduling = false
                    return
                }
                
                document.reference.updateData(taskData) { error in
                    isRescheduling = false
                    
                    if let error = error {
                        print("❌ Error updating task: \(error)")
                        return
                    }
                    
                    print("✅ Task rescheduled successfully for today")
                    
                    // Update local task manager if needed
                    TaskDataModel.shared.updateTask(task)
                    
                    // Signal update and dismiss
                    isUpdated = true
                }
            }
    }
}

#Preview {
    OverdueDetailsView(task: UserTask(
        taskName: "Morning Workout",
        description: "30-minute cardio session",
        startTime: "06:00 AM",
        endTime: "06:30 AM",
        date: Date(),
        priority: .medium,
        alert: .fiveMinutes,
        category: .sports
    ))
}
