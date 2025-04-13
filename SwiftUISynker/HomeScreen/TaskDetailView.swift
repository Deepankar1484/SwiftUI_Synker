import SwiftUI
import FirebaseFirestore

struct TaskDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    let loggedUser: User?
    
    @State private var task: UserTask
    @State private var showDeleteConfirmation = false
    @State private var showMarkCompleteConfirmation = false
    @State private var showEditView = false
    @State private var isUpdated = false
    @State private var isCompleting = false
    @State private var isDeleting = false // New state for deletion progress
    @State private var shouldNavigateBack = false
    
    private let db = Firestore.firestore()

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
                        .font(.system(size: 20, weight: .bold))
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
                
                // Task status section
                if task.isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Task Completed")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                } else if isCompleting {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 5)
                        Text("Marking as completed...")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                } else if isDeleting {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 5)
                        Text("Deleting task...")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                } else if isPastTask(task.date) {
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
                    if Calendar.current.isDate(Date(), inSameDayAs: task.date) {
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
            .padding()
        }
        .navigationBarTitle("Task Details", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !task.isCompleted && !isPastTask(task.date) && !isCompleting && !isDeleting {
                    Button("Edit") {
                        showEditView = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditView) {
            UpdateTaskView(isUpdated: $isUpdated, task: $task)
        }
        .alert("Delete Task", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
        .alert("Task Completed", isPresented: $showMarkCompleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Done") {
                markTaskAsComplete()
            }
        } message: {
            Text("Are you sure you have completed this task? This action cannot be undone.")
        }
        .onChange(of: isUpdated) { newValue in
            if newValue {
                showEditView = false
                isUpdated = false
            }
        }
        .onChange(of: shouldNavigateBack) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                    presentationMode.wrappedValue.dismiss()
                }
                shouldNavigateBack = false
            }
        }
        .disabled(isCompleting || isDeleting)
    }
    
    // MARK: - Firebase Functions
    
    private func markTaskAsComplete() {
        guard let user = loggedUser else {
            print("❌ No logged user available")
            return
        }
        
        isCompleting = true
        
        let tasksRef = db.collection("tasks")
        
        tasksRef.whereField("id", isEqualTo: task.id.uuidString)
               .whereField("userEmail", isEqualTo: user.email)
               .getDocuments { (querySnapshot, error) in
                   if let error = error {
                       print("❌ Error finding task: \(error)")
                       isCompleting = false
                       return
                   }
                   
                   guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                       print("❌ Task not found in Firestore")
                       isCompleting = false
                       return
                   }
                   
                   let document = documents[0]
                   
                   document.reference.updateData([
                       "isCompleted": true
                   ]) { error in
                       if let error = error {
                           print("❌ Error updating task: \(error)")
                           isCompleting = false
                           return
                       }
                       
                       print("✅ Task marked as completed successfully")
                       task.isCompleted = true
                       
                       DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                           isCompleting = false
                           DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                               shouldNavigateBack = true
                           }
                       }
                   }
               }
    }
    
    private func deleteTask() {
        guard let user = loggedUser else {
            print("❌ No logged user available")
            return
        }
        
        isDeleting = true
        
        let tasksRef = db.collection("tasks")
        
        tasksRef.whereField("id", isEqualTo: task.id.uuidString)
               .whereField("userEmail", isEqualTo: user.email)
               .getDocuments { (querySnapshot, error) in
                   if let error = error {
                       print("❌ Error finding task: \(error)")
                       isDeleting = false
                       return
                   }
                   
                   guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                       print("❌ Task not found in Firestore")
                       isDeleting = false
                       return
                   }
                   
                   let document = documents[0]
                   
                   document.reference.delete { error in
                       if let error = error {
                           print("❌ Error deleting task: \(error)")
                           isDeleting = false
                           return
                       }
                       
                       print("✅ Task deleted successfully from tasks collection")
                       updateUserTaskIds(email: user.email, taskId: task.id)
                   }
               }
    }
    
    private func updateUserTaskIds(email: String, taskId: UUID) {
        let usersRef = db.collection("users")
        
        usersRef.whereField("email", isEqualTo: email)
               .getDocuments { (querySnapshot, error) in
                   if let error = error {
                       print("❌ Error finding user: \(error)")
                       isDeleting = false
                       return
                   }
                   
                   guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                       print("❌ User not found in Firestore")
                       isDeleting = false
                       return
                   }
                   
                   let userDoc = documents[0]
                   
                   guard var taskIds = userDoc.data()["taskIds"] as? [String] else {
                       print("❌ No taskIds field in user document")
                       isDeleting = false
                       return
                   }
                   
                   taskIds.removeAll { $0 == taskId.uuidString }
                   
                   userDoc.reference.updateData([
                       "taskIds": taskIds
                   ]) { error in
                       if let error = error {
                           print("❌ Error updating user taskIds: \(error)")
                           isDeleting = false
                           return
                       }
                       
                       print("✅ User taskIds updated successfully")
                       
                       DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                           isDeleting = false
                           DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                               shouldNavigateBack = true
                           }
                       }
                   }
               }
    }
    
    private func isPastTask(_ taskDate: Date) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let selectedDay = Calendar.current.startOfDay(for: taskDate)
        return selectedDay < today
    }
}
