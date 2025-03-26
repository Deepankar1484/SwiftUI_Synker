import SwiftUI

struct TaskDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let loggedUser: User?
    
    @State private var task: UserTask // Make task mutable for editing
    @State private var showDeleteConfirmation = false
    @State private var showMarkCompleteConfirmation = false
    @State private var showEditView = false // Controls the presentation of UpdateTaskView
    @State private var isUpdated = false // Tracks if the task was updated

    init(task: UserTask, loggedUser: User?) {
        self._task = State(initialValue: task)
        self.loggedUser = loggedUser
    }
    
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
                
                if !task.isCompleted {
                    if isPastTask(task.date) {
                        VStack {
                            Text("This task is from the past and is not completed.")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.vertical,8)
                                .padding(.horizontal,0)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 10)
                    } else {
                        if Calendar.current.isDate(Date(), inSameDayAs: task.date){
                            Button(action: {
                                showMarkCompleteConfirmation = true
                            }) {
                                Text("Mark as Completed")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                        
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Text("Delete Task")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                    }
                }

            }
            .padding()
        }
        .navigationBarTitle("Task Details", displayMode: .inline)
        .navigationBarItems(trailing:
            (task.isCompleted || isPastTask(task.date)) ? nil : Button("Edit") {
                showEditView = true // Open UpdateTaskView
            }
        )
        .sheet(isPresented: $showEditView) {
            UpdateTaskView(isUpdated: $isUpdated, task: $task)
        }
        .alert("Delete Task", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                let taskModel = TaskDataModel.shared
                if let user = loggedUser {
                    let checkDelete = taskModel.deleteTask(with: task.id, for: user.userId)
                    if checkDelete {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
        .alert("Task Completed", isPresented: $showMarkCompleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Done") {
                let taskModel = TaskDataModel.shared
                let checkComplete = taskModel.markTaskAsComplete(taskId: task.id)
                if checkComplete {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text("Are you sure you have completed this task? This action cannot be undone.")
        }
    }
    private func isPastTask(_ taskDate: Date) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let selectedDay = Calendar.current.startOfDay(for: taskDate)
        return selectedDay < today
    }
    
}
