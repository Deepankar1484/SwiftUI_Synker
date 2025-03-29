import SwiftUI

struct TimeCapsuleDetailView: View {
    var capsule: TimeCapsule
    var loggedUser: User?
    var subtasks: [Subtask]
    @State private var showingCompletionAlert = false
    @State private var showDeleteConfirmation = false
    @State private var selectedSubtaskId: UUID?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Card
                VStack(alignment: .leading, spacing: 16) {
                    // Title and progress bar
                    VStack(alignment: .leading, spacing: 8) {
                        Text(capsule.capsuleName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Linear progress bar
                        VStack(alignment: .leading, spacing: 4) {
                            // Progress      40%
                            HStack {
                                Text("Progress")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(Int(capsule.completionPercentage))%")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            // the line part
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 10)
                                    
                                    // Progress
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(progressColor(percentage: capsule.completionPercentage))
                                        .frame(width: max(geometry.size.width * CGFloat(capsule.completionPercentage) / 100, 0), height: 10)
                                }
                            }
                            .frame(height: 10)
                        }
                    }
                    
                    Divider()
                    
                    // Metadata with modern indicators
                    HStack(spacing: 16) {
                        MetadataItemView(
                            title: "Deadline",
                            value: dateFormatter.string(from: capsule.deadline),
                            iconName: "calendar",
                            iconColor: .blue
                        )
                        
                        MetadataItemView(
                            title: "Priority",
                            value: capsule.priority.rawValue,
                            iconName: "flag.fill",
                            iconColor: Color(capsule.priority.tintColor),
                            valueColor: Color(capsule.priority.tintColor)
                        )
                        
                        MetadataItemView(
                            title: "Category",
                            value: capsule.category.rawValue,
                            iconName: capsule.category.taskImage,
                            iconColor: Color(capsule.category.customCategory.categoryColor),
                            valueColor: Color(capsule.category.customCategory.categoryColor)
                        )
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                // Description section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(capsule.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                // Subtasks section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Subtasks")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Subtask counter pill
                        Text("\(subtasks.filter(\.isCompleted).count)/\(subtasks.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal)
                    
                    if subtasks.isEmpty {
                        EmptySubtasksView()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(subtasks, id: \.subtaskId) { subtask in
                                SubtaskCardView(
                                    subtask: subtask,
                                    onTap: {
                                        if !subtask.isCompleted {
                                            selectedSubtaskId = subtask.subtaskId
                                            showingCompletionAlert = true
                                        }
                                    },
                                    onDelete: {
                                        let taskModel = TaskDataModel.shared
                                        let check = taskModel.deleteSubtask(with: subtask.subtaskId, from: capsule.id)
                                        if check {
                                            dismiss()
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if capsule.completionPercentage < 100 {
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
                        .padding()
                    }
                }
                
                
            }
            .padding(.vertical)
        }
        .navigationTitle("Capsule Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .alert("Mark as Complete", isPresented: $showingCompletionAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Mark Complete") {
                if let subtaskId = selectedSubtaskId {
                    let taskModel = TaskDataModel.shared
                    let success = taskModel.markSubtaskComplete(subtaskId: subtaskId, capsuleId: capsule.id)
                    
                    if success {
                        // If all subtasks are now completed, dismiss the view
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Do you want to mark this subtask as complete?")
        }
        .alert("Delete Task", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                let taskModel = TaskDataModel.shared
                if let user = loggedUser {
                    let checkDeleteCapsule = taskModel.deleteTimeCapsule(with: capsule.id, for: user.userId)
                    if checkDeleteCapsule {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
    
    // Helper function for progress color
    private func progressColor(percentage: Double) -> Color {
        if percentage < 40 {
            return .red
        } else if percentage < 70 {
            return .orange
        } else {
            return .green
        }
    }
}

// Reusable Metadata Item component
struct MetadataItemView: View {
    var title: String
    var value: String
    var iconName: String
    var iconColor: Color
    var valueColor: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            } icon: {
                if(iconName == "Others"){
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15) // Bigger icon
                        .foregroundColor(.white)
                } else {
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                }
            }
            
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(valueColor ?? .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Empty state view for subtasks
struct EmptySubtasksView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No subtasks added yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Add subtasks to break down this capsule into smaller, manageable pieces")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// Modernized subtask card with delete button
struct SubtaskCardView: View {
    var subtask: Subtask
    var onTap: () -> Void
    var onDelete: () -> Void // Closure for delete action

    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(alignment: .center) {
                    ZStack {
                        Circle()
                            .stroke(subtask.isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                        
                        if subtask.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(subtask.subtaskName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(subtask.isCompleted ? .gray : .primary)
                        .strikethrough(subtask.isCompleted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Delete Button with Alert Trigger
                if !subtask.isCompleted{
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if !subtask.description.isEmpty {
                Text(subtask.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 32)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .alert("Delete Subtask", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this subtask? This action cannot be undone.")
        }
    }
}

// MARK: - Date Formatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

// MARK: - Preview
#Preview {
    let sampleCapsule = TimeCapsule(
        capsuleName: "Develop iOS App",
        deadline: Date().addingTimeInterval(86400 * 5), // 5 days from now
        priority: .high,
        description: "Create a productivity app for iOS using SwiftUI with time capsule functionality and task tracking. This will help users organize their tasks and improve productivity.",
        category: .work
    )
    
    let sampleSubtasks = [
        Subtask(subtaskName: "Research UI Components", description: "Look for SwiftUI components that can be used for the app. Focus on modern, clean design that's easy to use.", isCompleted: true),
        Subtask(subtaskName: "Create Data Models", description: "Define the data structures needed for the app, including TimeCapsule and Subtask models.", isCompleted: true),
        Subtask(subtaskName: "Implement Core Logic", description: "Write the business logic for the app, including calculations for completion percentages.", isCompleted: false),
        Subtask(subtaskName: "Create UI Screens", description: "Design and implement the main UI screens, including list views and detail views.", isCompleted: false),
        Subtask(subtaskName: "Add Persistence", description: "Implement data persistence using CoreData to save user data.", isCompleted: false)
    ]
    
    var updatedCapsule = sampleCapsule
    updatedCapsule.updateCompletionPercentage(subtasks: sampleSubtasks)
    
    return NavigationStack {
        TimeCapsuleDetailView(capsule: updatedCapsule, subtasks: sampleSubtasks)
    }
}
