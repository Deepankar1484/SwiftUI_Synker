import SwiftUI

struct TimeCapsuleScreen: View {
    @State private var timeCapsules: [TimeCapsule] = []
    @State private var subtasks: [UUID: [Subtask]] = [:]
    @State private var selectedFilter: TaskFilter = .allCapsules
    let taskModel = TaskDataModel.shared
    @State var loggedUser: User?
    
    enum TaskFilter {
        case allCapsules
        case active
        case completed
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Display top Capsule with the nearest deadline (only for active tasks)
                    if let topCapsule = getActiveCapsules().min(by: { $0.deadline < $1.deadline }) {
                        NavigationLink(destination: TimeCapsuleDetailView(capsule: topCapsule, loggedUser: loggedUser, subtasks: subtasks[topCapsule.id] ?? [])) {
                            TopCapsuleItemView(capsule: topCapsule)
                                .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle()) // Removes default button styling
//                        Text("Hurry up! Time's ticking!")
//                            .font(.subheadline)
//                            .padding(.horizontal)
//                            .foregroundColor(.red)
//                            .frame(maxWidth: .infinity, alignment: .center)
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
                    
                    // Filtered Capsules List
                    let filteredCapsules = getFilteredCapsules()
                    if !filteredCapsules.isEmpty {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredCapsules, id: \.id) { capsule in
                                NavigationLink(destination: TimeCapsuleDetailView(capsule: capsule, loggedUser: loggedUser, subtasks: subtasks[capsule.id] ?? [])) {
                                    CapsuleItemView(capsule: capsule)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    } else {
                        Text("No capsules found")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 20)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Time Capsule")
            .onAppear {
                fetchTimeCapsules()
            }
        }
    }
    
    // Fetch time capsules from TaskDataModel
    private func fetchTimeCapsules() {
        let taskModel = TaskDataModel.shared
        if let user = loggedUser {
            timeCapsules = taskModel.getAllTimeCapsules(for: user.userId)
            let currentUser = taskModel.getUser(by: user.userId)
            if let currentUser = currentUser {
                for capsuleId in currentUser.timeCapsuleIds {
                    subtasks[capsuleId] = taskModel.getSubtasks(for: capsuleId)
                }
            }
        }
//        guard let x = loggedUser else { return }
//        loggedUser = taskModel.getUser(by: x.userId)
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
