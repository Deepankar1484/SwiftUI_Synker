import SwiftUI
import FirebaseFirestore

struct TimeCapsuleDetailView: View {
    var capsule: TimeCapsule
    var loggedUser: User?
    @State private var subtasks: [Subtask] = []
    @State private var showingCompletionAlert = false
    @State private var showDeleteConfirmation = false
    @State private var selectedSubtaskId: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var updatedCompletionPercentage: Double = 0.0
    
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
                            // Progress percentage
                            HStack {
                                Text("Progress")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(Int(isLoading ? capsule.completionPercentage : updatedCompletionPercentage))%")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            // The progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 10)
                                    
                                    // Progress
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(progressColor(percentage: isLoading ? capsule.completionPercentage : updatedCompletionPercentage))
                                        .frame(width: max(geometry.size.width * CGFloat(isLoading ? capsule.completionPercentage : updatedCompletionPercentage) / 100, 0), height: 10)
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
                    
                    if isLoading {
                        VStack {
                            ProgressView("Loading subtasks...")
                                .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else if subtasks.isEmpty {
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
                                        deleteSubtask(subtask)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if !isLoading && (updatedCompletionPercentage < 100 || capsule.completionPercentage < 100) {
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
        .onAppear {
            fetchSubtasksFromFirebase()
        }
        .alert("Mark as Complete", isPresented: $showingCompletionAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Mark Complete") {
                if let subtaskId = selectedSubtaskId {
                    markSubtaskComplete(subtaskId: subtaskId)
                }
            }
        } message: {
            Text("Do you want to mark this subtask as complete?")
        }
        .alert("Delete Task", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTimeCapsule()
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
    
    // MARK: - Firebase Functions
    
    private func fetchSubtasksFromFirebase() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        let subtaskIds = capsule.subtaskIds.map { $0.uuidString }
        
        if subtaskIds.isEmpty {
            isLoading = false
            updateCompletionPercentage()
            return
        }
        
        db.collection("subtasks")
            .whereField("id", in: subtaskIds)
            .getDocuments(source: .default) { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching subtasks: \(error.localizedDescription)")
                    errorMessage = "Failed to load subtasks: \(error.localizedDescription)"
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    isLoading = false
                    return
                }
                
                var fetchedSubtasks: [Subtask] = []
                
                for doc in documents {
                    let data = doc.data()
                    
                    guard
                        let subtaskIdString = data["id"] as? String,
                        let subtaskId = UUID(uuidString: subtaskIdString),
                        let name = data["subtaskName"] as? String,
                        let description = data["description"] as? String,
                        let isCompleted = data["isCompleted"] as? Bool
                    else {
                        continue
                    }
                    
                    let subtask = Subtask(
                        subtaskId: subtaskId,
                        subtaskName: name,
                        description: description,
                        isCompleted: isCompleted
                    )
                    
                    fetchedSubtasks.append(subtask)
                }
                
                self.subtasks = fetchedSubtasks
                updateCompletionPercentage()
                isLoading = false
            }
    }
    
    private func updateCompletionPercentage() {
        if subtasks.isEmpty {
            updatedCompletionPercentage = 0.0
        } else {
            let completedCount = subtasks.filter { $0.isCompleted }.count
            updatedCompletionPercentage = Double(completedCount) / Double(subtasks.count) * 100.0
        }
        
        // Update the percentage in Firebase
        updateCapsuleCompletionPercentage()
    }
    
    private func updateCapsuleCompletionPercentage() {
        let db = Firestore.firestore()
        
        db.collection("timeCapsules")
            .whereField("id", isEqualTo: capsule.id.uuidString)
            .getDocuments(source: .default) { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching time capsule: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("⚠️ No time capsule found with id: \(capsule.id)")
                    return
                }
                
                // Update the completion percentage
                document.reference.updateData([
                    "completionPercentage": updatedCompletionPercentage
                ]) { error in
                    if let error = error {
                        print("❌ Error updating completion percentage: \(error.localizedDescription)")
                    } else {
                        print("✅ Time capsule completion percentage updated successfully")
                    }
                }
            }
    }
    
    private func markSubtaskComplete(subtaskId: UUID) {
        let db = Firestore.firestore()
        
        db.collection("subtasks")
            .whereField("id", isEqualTo: subtaskId.uuidString)
            .getDocuments(source: .default) { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching subtask: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("⚠️ No subtask found with id: \(subtaskId)")
                    return
                }
                
                // Mark the subtask as completed
                document.reference.updateData([
                    "isCompleted": true
                ]) { error in
                    if let error = error {
                        print("❌ Error marking subtask as complete: \(error.localizedDescription)")
                    } else {
                        print("✅ Subtask marked as complete successfully")
                        
                        // Update local state
                        if let index = subtasks.firstIndex(where: { $0.subtaskId == subtaskId }) {
                            subtasks[index].isCompleted = true
                        }
                        
                        // Recalculate completion percentage
                        updateCompletionPercentage()
                        
                        // If all subtasks are completed, dismiss the view
                        if subtasks.allSatisfy({ $0.isCompleted }) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                dismiss()
                            }
                        }
                    }
                }
            }
    }
    
    private func deleteSubtask(_ subtask: Subtask) {
        let db = Firestore.firestore()
        
        // 1. Delete the subtask document
        db.collection("subtasks")
            .whereField("id", isEqualTo: subtask.subtaskId.uuidString)
            .getDocuments(source: .default) { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching subtask: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("⚠️ No subtask found with id: \(subtask.subtaskId)")
                    return
                }
                
                document.reference.delete { error in
                    if let error = error {
                        print("❌ Error deleting subtask: \(error.localizedDescription)")
                    } else {
                        print("✅ Subtask deleted successfully")
                        
                        // 2. Update time capsule subtaskIds array
                        removeSubtaskIdFromTimeCapsule(subtaskId: subtask.subtaskId)
                        
                        // 3. Update local state
                        subtasks.removeAll { $0.subtaskId == subtask.subtaskId }
                        
                        // 4. Recalculate completion percentage
                        updateCompletionPercentage()
                    }
                }
            }
    }
    
    private func removeSubtaskIdFromTimeCapsule(subtaskId: UUID) {
        let db = Firestore.firestore()
        
        db.collection("timeCapsules")
            .whereField("id", isEqualTo: capsule.id.uuidString)
            .getDocuments(source: .default) { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching time capsule: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("⚠️ No time capsule found with id: \(capsule.id)")
                    return
                }
                
                // Get current subtaskIds
                guard let subtaskIdStrings = document.data()["subtaskIds"] as? [String] else {
                    print("⚠️ No subtaskIds found in time capsule")
                    return
                }
                
                // Remove the subtaskId
                let updatedSubtaskIds = subtaskIdStrings.filter { $0 != subtaskId.uuidString }
                
                // Update the document
                document.reference.updateData([
                    "subtaskIds": updatedSubtaskIds
                ]) { error in
                    if let error = error {
                        print("❌ Error updating subtaskIds: \(error.localizedDescription)")
                    } else {
                        print("✅ Removed subtaskId from time capsule successfully")
                    }
                }
            }
    }
    
    private func deleteTimeCapsule() {
        guard let loggedUser = loggedUser else {
            print("❌ No logged user found")
            return
        }
        
        let db = Firestore.firestore()
        
        // 1. Delete all subtasks first
        for subtask in subtasks {
            db.collection("subtasks")
                .whereField("id", isEqualTo: subtask.subtaskId.uuidString)
                .getDocuments(source: .default) { (snapshot, error) in
                    if let error = error {
                        print("❌ Error fetching subtask: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let document = snapshot?.documents.first else { return }
                    
                    document.reference.delete { error in
                        if let error = error {
                            print("❌ Error deleting subtask: \(error.localizedDescription)")
                        }
                    }
                }
        }
        
        // 2. Delete the time capsule
        db.collection("timeCapsules")
            .whereField("id", isEqualTo: capsule.id.uuidString)
            .getDocuments(source: .default) { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching time capsule: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("⚠️ No time capsule found with id: \(capsule.id)")
                    return
                }
                
                document.reference.delete { error in
                    if let error = error {
                        print("❌ Error deleting time capsule: \(error.localizedDescription)")
                    } else {
                        print("✅ Time capsule deleted successfully")
                        
                        // 3. Remove time capsule ID from user
                        removeTimeCapsuleIdFromUser()
                    }
                }
            }
    }
    
    private func removeTimeCapsuleIdFromUser() {
        let db = Firestore.firestore()
        
        db.collection("users")
            .whereField("email", isEqualTo: loggedUser?.email ?? "")
            .getDocuments(source: .default) { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching user: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("⚠️ No user found with email: \(loggedUser?.email ?? "")")
                    return
                }
                
                // Get current timeCapsuleIds
                guard let timeCapsuleIdStrings = document.data()["timeCapsuleIds"] as? [String] else {
                    print("⚠️ No timeCapsuleIds found for user")
                    return
                }
                
                // Remove the time capsule ID
                let updatedTimeCapsuleIds = timeCapsuleIdStrings.filter { $0 != capsule.id.uuidString }
                
                // Update the document
                document.reference.updateData([
                    "timeCapsuleIds": updatedTimeCapsuleIds
                ]) { error in
                    if let error = error {
                        print("❌ Error updating user timeCapsuleIds: \(error.localizedDescription)")
                    } else {
                        print("✅ Removed time capsule ID from user successfully")
                        
                        // Dismiss the view
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    }
                }
            }
    }
}

// MARK: - Supporting Views
// Keep the existing supporting view structures (MetadataItemView, EmptySubtasksView, SubtaskCardView) as they were

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
                        .frame(width: 15, height: 15)
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
    var onDelete: () -> Void

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
