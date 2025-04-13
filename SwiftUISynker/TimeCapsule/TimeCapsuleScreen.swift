import SwiftUI
import FirebaseFirestore

struct TimeCapsuleScreen: View {
    @State private var timeCapsules: [TimeCapsule] = []
    @State private var subtasks: [UUID: [Subtask]] = [:]
    @State private var selectedFilter: TaskFilter = .allCapsules
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    let taskModel = TaskDataModel.shared
    @State var loggedUser: User?
    
    enum TaskFilter {
        case allCapsules
        case active
        case completed
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // Display top Capsule with the nearest deadline (only for active tasks)
                        if let topCapsule = getActiveCapsules().min(by: { $0.deadline < $1.deadline }) {
                            NavigationLink(destination: TimeCapsuleDetailView(capsule: topCapsule, loggedUser: loggedUser)) {
                                TopCapsuleItemView(capsule: topCapsule)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Text("My Capsules")
                            .font(.title2).bold()
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        // Segmented picker for filtering
                        Picker("Task Filter", selection: $selectedFilter) {
                            Text("All Capsules").tag(TaskFilter.allCapsules)
                            Text("Active").tag(TaskFilter.active)
                            Text("Completed").tag(TaskFilter.completed)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Error message if there's any
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Filtered Capsules List
                        let filteredCapsules = getFilteredCapsules()
                        if !filteredCapsules.isEmpty {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredCapsules, id: \.id) { capsule in
                                    NavigationLink(destination: TimeCapsuleDetailView(capsule: capsule, loggedUser: loggedUser)) {
                                        CapsuleItemView(capsule: capsule)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        } else {
                            if !isLoading {
                                Text("No capsules found")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 20)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                
                // Loading indicator
                if isLoading {
                    ProgressView("Loading capsules...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Time Capsule")
            .onAppear {
                fetchTimeCapsules()
            }
        }
    }
    
    // New fetchTimeCapsules function that uses Firebase
    private func fetchTimeCapsules() {
        guard let user = loggedUser, !user.email.isEmpty else {
            errorMessage = "No logged in user or invalid email"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Get all time capsules for the user's email
        getAllTimeCapsules(forEmail: user.email) { fetchedCapsules in
            // Now fetch all subtasks for each capsule
            let group = DispatchGroup()
            var allSubtasks: [UUID: [Subtask]] = [:]
            
            for capsule in fetchedCapsules {
                group.enter()
                fetchSubtasks(forCapsuleId: capsule.id) { fetchedSubtasks in
                    allSubtasks[capsule.id] = fetchedSubtasks
                    
                    // Update completion percentage based on fetched subtasks
                    if let index = fetchedCapsules.firstIndex(where: { $0.id == capsule.id }) {
                        var updatedCapsule = fetchedCapsules[index]
                        updatedCapsule.updateCompletionPercentage(subtasks: fetchedSubtasks)
                        DispatchQueue.main.async {
                            if let updateIndex = self.timeCapsules.firstIndex(where: { $0.id == capsule.id }) {
                                self.timeCapsules[updateIndex] = updatedCapsule
                            }
                        }
                    }
                    
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.timeCapsules = fetchedCapsules
                self.subtasks = allSubtasks
                self.isLoading = false
            }
        }
    }
    
    // Function to fetch all time capsules for a specific email
    private func getAllTimeCapsules(forEmail email: String, completion: @escaping ([TimeCapsule]) -> Void) {
        let db = Firestore.firestore()
        
        // Step 1: Fetch the user by email
        db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments(source: .default) { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching user: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to fetch user data: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                    completion([])
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("⚠️ No user found with email: \(email)")
                    DispatchQueue.main.async {
                        self.errorMessage = "No user found with this email"
                        self.isLoading = false
                    }
                    completion([])
                    return
                }

                let data = document.data()
                
                // Step 2: Extract time capsule IDs
                guard let timeCapsuleIdStrings = data["timeCapsuleIds"] as? [String], !timeCapsuleIdStrings.isEmpty else {
                    print("⚠️ No time capsule IDs found for user.")
                    DispatchQueue.main.async {
                        self.errorMessage = nil // No error, just no capsules
                        self.isLoading = false
                    }
                    completion([])
                    return
                }

                // Step 3: Query timeCapsules collection for matching IDs
                db.collection("timeCapsules")
                    .whereField("id", in: timeCapsuleIdStrings)
                    .getDocuments(source: .default) { (capsuleSnapshot, error) in
                        if let error = error {
                            print("❌ Error fetching time capsules: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self.errorMessage = "Failed to fetch time capsules: \(error.localizedDescription)"
                                self.isLoading = false
                            }
                            completion([])
                            return
                        }

                        guard let capsuleDocs = capsuleSnapshot?.documents else {
                            print("⚠️ No matching time capsules found.")
                            DispatchQueue.main.async {
                                self.errorMessage = nil // No error, just no capsules
                                self.isLoading = false
                            }
                            completion([])
                            return
                        }

                        var fetchedCapsules: [TimeCapsule] = []

                        for doc in capsuleDocs {
                            let data = doc.data()

                            guard
                                let name = data["capsuleName"] as? String,
                                let deadlineTimestamp = data["deadline"] as? Timestamp,
                                let priorityRaw = data["priority"] as? String,
                                let desc = data["description"] as? String,
                                let perc=data["completionPercentage"] as? Double,
                                let categoryRaw = data["category"] as? String,
                                let subtaskIdStrings = data["subtaskIds"] as? [String],
                                let capsuleIdString = data["id"] as? String,
                                let capsuleId = UUID(uuidString: capsuleIdString),
                                let priority = Priority(rawValue: priorityRaw),
                                let category = Category(rawValue: categoryRaw)
                            else {
                                print("⚠️ Skipping invalid capsule data in document: \(doc.documentID)")
                                continue
                            }

                            let subtaskUUIDs = subtaskIdStrings.compactMap { UUID(uuidString: $0) }

                            var capsule = TimeCapsule(
                                
                                capsuleName: name,
                                deadline: deadlineTimestamp.dateValue(),
                                priority: priority,
                                description: desc,
                                category: category
                               
                            )
                            
                            capsule.id=capsuleId
                            capsule.completionPercentage=perc
                            capsule.subtaskIds=subtaskUUIDs
                            
                            fetchedCapsules.append(capsule)
                        }

                        completion(fetchedCapsules)
                    }
            }
    }
    
    // Function to fetch subtasks for a specific capsule
    private func fetchSubtasks(forCapsuleId capsuleId: UUID, completion: @escaping ([Subtask]) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("subtasks")
            .whereField("capsuleId", isEqualTo: capsuleId.uuidString)
            .getDocuments(source: .default) { (snapshot, error) in
                if let error = error {
                    print("❌ Error fetching subtasks: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No subtasks found for capsule ID: \(capsuleId)")
                    completion([])
                    return
                }
                
                var subtasks: [Subtask] = []
                
                for doc in documents {
                    let data = doc.data()
                    
                    guard
                        let subtaskIdString = data["id"] as? String,
                        let subtaskId = UUID(uuidString: subtaskIdString),
                        let name = data["subtaskName"] as? String,
                        let description = data["description"] as? String,
                        let isCompleted = data["isCompleted"] as? Bool
                    else {
                        print("⚠️ Skipping invalid subtask data in document: \(doc.documentID)")
                        continue
                    }
                    
                    let subtask = Subtask(
                        subtaskId: subtaskId,
                        subtaskName: name,
                        description: description,
                        isCompleted: isCompleted
                    )
                    
                    subtasks.append(subtask)
                }
                
                completion(subtasks)
            }
    }
    
    // Get active capsules (not 100% completed)
    private func getActiveCapsules() -> [TimeCapsule] {
        return timeCapsules.filter { $0.completionPercentage < 100 }
    }
    
    // Get completed capsules (100% completed)
    private func getCompletedCapsules() -> [TimeCapsule] {
        return timeCapsules.filter { $0.completionPercentage == 100 }
    }
    
    // Get filtered capsules based on selected filter
    private func getFilteredCapsules() -> [TimeCapsule] {
        switch selectedFilter {
        case .allCapsules:
            return timeCapsules
        case .active:
            return timeCapsules.filter { $0.completionPercentage > 0 && $0.completionPercentage < 100 }
        case .completed:
            return timeCapsules.filter { $0.completionPercentage == 100 }
        }
    }
}

// MARK: - Top Capsule Item View
struct TopCapsuleItemView: View {
    var capsule: TimeCapsule
    
    var body: some View {
        HStack(spacing: 30) {
            CircularProgressTimeCapsuleView(progress: capsule.completionPercentage, size: 70)
            
            VStack(alignment: .leading) {
                Text(capsule.capsuleName)
                    .font(.title2).bold()
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .truncationMode(.tail)
                Text("Due in \(daysUntilDeadline(capsule.deadline)) days")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.red.opacity(0.8).gradient)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

// MARK: - Other Capsules Item View
struct CapsuleItemView: View {
    var capsule: TimeCapsule
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(capsule.priority.tintColor))
                .frame(width: 15, height: 15)
            
            VStack(alignment: .leading) {
                Text(capsule.capsuleName)
                    .font(.headline)
                Text("Due in \(daysUntilDeadline(capsule.deadline)) days")
                    .font(.subheadline)
            }
            Spacer()
            CircularProgressTimeCapsuleView(progress: capsule.completionPercentage, size: 40)
        }
        .padding()
        .background(Color.purple.opacity(0.5))
        .cornerRadius(10)
    }
}

// MARK: - Circular Progress View
struct CircularProgressTimeCapsuleView: View {
    var progress: Double
    var size: CGFloat = 40
    
    var body: some View {
        ZStack {
            if (Int(progress) < 100) {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 5)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(progress / 100))
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                // Percentage text
                Text("\(Int(progress))%")
                    .font(size > 50 ? .body.bold() : .caption.bold())
                    .foregroundColor(.white)
            } else {
                // Completed background
                Circle()
                    .fill(Color.green)
                
                // Checkmark
                ZStack {
                    // White circle background for checkmark
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.85, height: size * 0.85)
                    
                    // Green checkmark
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.green)
                        .frame(width: size * 0.85, height: size * 0.85)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
        }
        .frame(width: size, height: size)
    }
}
// MARK: - Days Until Deadline Function
func daysUntilDeadline(_ date: Date) -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let deadline = calendar.startOfDay(for: date)
    let components = calendar.dateComponents([.day], from: today, to: deadline)
    return components.day ?? 0
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TimeCapsuleScreen()
    }
}
