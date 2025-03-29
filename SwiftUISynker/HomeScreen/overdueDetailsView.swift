import SwiftUI

struct OverdueDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var loggedUser: User?
    @State var task: UserTask // Task details
    @State private var showEditView = false
    @State private var isUpdated = false
    @State private var showRescheduleAlert = false
    
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
                    Button("Done") {
                        rescheduleTaskForToday()
                    }
                } message: {
                    Text("Are you sure you want to reschedule this task for today?")
                }
                
                Button(action: {
                    showEditView = true
                }) {
                    Text("Reschedule Task")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding(.bottom, 10)
                
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
        task.date = Date() // Set task date to today
        let taskModel = TaskDataModel.shared
        taskModel.updateTask(task)
        isUpdated = true // Trigger update
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
