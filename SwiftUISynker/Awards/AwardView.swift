import SwiftUI
import FirebaseFirestore

struct AwardsView: View {
    @State var loggedUser: User?
    @State private var currentStreak = 0
    @State private var maxStreak = 0
    @State private var isLoading = false
    
    private let db = Firestore.firestore()
    
    // Define all possible awards (both earned and available)
    private let allAwards: [AwardsEarned] = [
        AwardsEarned(
            awardName: "Weekly Streak!",
            description: "You've maintained a 7-day streak! Keep going!",
            awardImage: "🔥",
            dateEarned: Date()
        ),
        AwardsEarned(
            awardName: "Monthly Master",
            description: "30 days of consistency! You're unstoppable!",
            awardImage: "🏆",
            dateEarned: Date()
        ),
        AwardsEarned(
            awardName: "3-Month Legend",
            description: "90 days of dedication! You're amazing!",
            awardImage: "🌟",
            dateEarned: Date()
        ),
        AwardsEarned(
            awardName: "6-Month Champion",
            description: "Half a year of commitment! Incredible!",
            awardImage: "💎",
            dateEarned: Date()
        ),
        AwardsEarned(
            awardName: "Yearly Titan",
            description: "A full year of consistency! You're phenomenal!",
            awardImage: "🚀",
            dateEarned: Date()
        )
    ]
    
    // Dictionary for streak-based awards (used for checking eligibility)
    private var streakAwards: [Int: AwardsEarned] {
        var dict = [Int: AwardsEarned]()
        for award in allAwards {
            if award.awardName == "Weekly Streak!" {
                dict[7] = award
            } else if award.awardName == "Monthly Master" {
                dict[30] = award
            } else if award.awardName == "3-Month Legend" {
                dict[90] = award
            } else if award.awardName == "6-Month Champion" {
                dict[180] = award
            } else if award.awardName == "Yearly Titan" {
                dict[365] = award
            }
        }
        return dict
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Awards")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Streak Stats
                HStack {
                    StreakCard(title: "Current streak", value: "\(currentStreak) Days", icon: "flame.fill")
                    StreakCard(title: "Max streak", value: "\(maxStreak) Days", icon: "flame.fill")
                }
                .padding(.horizontal)
                
                // Show Earned Awards Only
                SectionHeader(title: "Earned Awards")
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let userAwards = loggedUser?.awardsEarned, !userAwards.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(userAwards) { award in
                                AwardCard(award: award, isEarned: true)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    Text("No awards earned yet.")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                
                // Available Awards Section
                SectionHeader(title: "Available Awards")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(allAwards) { award in
                            // Only show if not already earned
                            if !(loggedUser?.awardsEarned.contains { $0.awardName == award.awardName } ?? false) {
                                AwardCard(award: award, isEarned: false)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadUserData()
        }
    }
    private func loadUserData() {
        isLoading = true
        
        guard let userEmail = loggedUser?.email else {
            isLoading = false
            return
        }
        
        db.collection("users")
            .whereField("email", isEqualTo: userEmail)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, let document = documents.first else {
                    print("Error fetching user: \(error?.localizedDescription ?? "Unknown error")")
                    isLoading = false
                    return
                }
                
                do {
                    var userData = document.data()
                    
                    // Extract user ID
                    let userIdString = userData["userId"] as? String ?? ""
                    let userId = UUID(uuidString: userIdString) ?? UUID()
                    
                    // Extract basic user info
                    let name = userData["name"] as? String ?? ""
                    let email = userData["email"] as? String ?? ""
                    let password = userData["password"] as? String ?? ""
                    let phone = userData["phone"] as? String
                    
                    // Extract streaks
                    let totalStreak = userData["totalStreak"] as? Int ?? 0
                    let maxStreak = userData["maxStreak"] as? Int ?? 0
                    
                    // Create user with basic info
                    var user = User(name: name, email: email, password: password)
                    user.userId = userId
                    user.phone = phone
                    user.totalStreak = totalStreak
                    user.maxStreak = maxStreak
                    
                    // Extract awards
                    if let awardsData = userData["awardsEarned"] as? [[String: Any]] {
                        var awards: [AwardsEarned] = []
                        
                        for awardDict in awardsData {
                            if let awardName = awardDict["awardName"] as? String,
                               let description = awardDict["description"] as? String,
                               let awardImage = awardDict["awardImage"] as? String,
                               let dateTimestamp = awardDict["dateEarned"] as? Timestamp {
                                
                                let award = AwardsEarned(
                                    id: UUID(),
                                    awardName: awardName,
                                    description: description,
                                    awardImage: awardImage,
                                    dateEarned: dateTimestamp.dateValue()
                                )
                                awards.append(award)
                            }
                        }
                        
                        user.awardsEarned = awards
                    }
                    
                    // Update the logged user with fetched data
                    self.loggedUser = user
                    
                    // After loading user data, calculate streaks
                    calculateUserStreaks(userEmail: email)
                }
            }
    }
    
    private func calculateUserStreaks(userEmail: String) {
        // Get all user tasks
        db.collection("tasks")
            .whereField("userEmail", isEqualTo: userEmail)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching tasks: \(error?.localizedDescription ?? "Unknown error")")
                    self.isLoading = false
                    return
                }
                
                // Parse all tasks
                var allTasks: [UserTask] = []
                for document in documents {
                    let data = document.data()
                    
                    guard let taskName = data["taskName"] as? String,
                          let description = data["description"] as? String,
                          let startTime = data["startTime"] as? String,
                          let endTime = data["endTime"] as? String,
                          let dateTimestamp = data["date"] as? Timestamp,
                          let priorityRaw = data["priority"] as? String,
                          let alertRaw = data["alert"] as? String,
                          let categoryRaw = data["category"] as? String,
                          let isCompleted = data["isCompleted"] as? Bool else {
                        continue
                    }
                    
                    let date = dateTimestamp.dateValue()
                    let otherCategory = data["otherCategory"] as? String
                    
                    let priority = Priority(rawValue: priorityRaw) ?? .medium
                    let alert = Alert(rawValue: alertRaw) ?? .none
                    let category = Category(rawValue: categoryRaw) ?? .work
                    
                    let task = UserTask(
                        taskName: taskName,
                        description: description,
                        startTime: startTime,
                        endTime: endTime,
                        date: date,
                        priority: priority,
                        alert: alert,
                        category: category,
                        otherCategory: otherCategory,
                        isCompleted: isCompleted
                    )
                    
                    allTasks.append(task)
                }
                
                // Group tasks by day and calculate streaks
                self.calculateStreaksFromTasks(tasks: allTasks)
            }
    }
    
    private func calculateStreaksFromTasks(tasks: [UserTask]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Group tasks by day
        var tasksByDay: [Date: [UserTask]] = [:]
        
        for task in tasks {
            let taskDay = calendar.startOfDay(for: task.date)
            if tasksByDay[taskDay] == nil {
                tasksByDay[taskDay] = []
            }
            tasksByDay[taskDay]?.append(task)
        }
        
        // Filter days where at least one task was completed
        var daysWithCompletedTasks: [Date] = []
        for (day, tasks) in tasksByDay {
            if tasks.contains(where: { $0.isCompleted }) {
                daysWithCompletedTasks.append(day)
            }
        }
        
        // Sort days in chronological order (oldest first)
        daysWithCompletedTasks.sort()
        
        // Calculate current streak
        var currentStreakCount = 0
        
        if daysWithCompletedTasks.isEmpty {
            currentStreakCount = 0
        } else {
            // Get the latest day with a completed task
            let latestDayWithCompletedTask = daysWithCompletedTasks.last!
            
            // If latest day is before yesterday, streak is broken
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if latestDayWithCompletedTask < yesterday {
                currentStreakCount = 0
            } else {
                // Start counting from the latest day backward
                currentStreakCount = 1
                var currentDay = latestDayWithCompletedTask
                
                // Go backward through all days with completed tasks
                for i in (0..<daysWithCompletedTasks.count-1).reversed() {
                    let previousDay = daysWithCompletedTasks[i]
                    let expectedPreviousDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
                    
                    // Check if days are consecutive
                    if calendar.isDate(previousDay, inSameDayAs: expectedPreviousDay) {
                        currentStreakCount += 1
                        currentDay = previousDay
                    } else {
                        break
                    }
                }
            }
        }
        
        // Update UI and data
        self.currentStreak = currentStreakCount
        
        // Calculate max streak (take the existing one or the current if it's greater)
        if let existingMaxStreak = self.loggedUser?.maxStreak {
            self.maxStreak = max(existingMaxStreak, currentStreakCount)
        } else {
            self.maxStreak = currentStreakCount
        }
        
        // Check if user qualifies for any new awards
        checkForNewAwards(currentStreak: currentStreakCount)
        
        // Update user document with new streak values
        self.updateUserStreaks(current: currentStreakCount, max: self.maxStreak)
        
        self.isLoading = false
    }
    
    private func checkForNewAwards(currentStreak: Int) {
        guard let email = loggedUser?.email else { return }
        
        // Check if current streak matches any milestone
        if let award = streakAwards[currentStreak] {
            // Check if user already has this award
            let awardAlreadyEarned = loggedUser?.awardsEarned.contains { $0.awardName == award.awardName } ?? false
            
            if !awardAlreadyEarned {
                // Add the new award
                var updatedAwards = loggedUser?.awardsEarned ?? []
                updatedAwards.append(award)
                loggedUser?.awardsEarned = updatedAwards
                
                // Update Firestore
                updateUserAwards(email: email, newAward: award)
            }
        }
    }
    
    private func updateUserAwards(email: String, newAward: AwardsEarned) {
        // Convert the award to dictionary
        let awardDict: [String: Any] = [
            "id": newAward.id.uuidString,
            "awardName": newAward.awardName,
            "description": newAward.description,
            "awardImage": newAward.awardImage,
            "dateEarned": Timestamp(date: newAward.dateEarned)
        ]
        
        db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error searching user: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No users found with this email")
                    return
                }
                
                // Assuming email is unique, we take the first document
                if let userDoc = documents.first {
                    // Update the awards array
                    userDoc.reference.updateData([
                        "awardsEarned": FieldValue.arrayUnion([awardDict])
                    ]) { error in
                        if let error = error {
                            print("Error updating awards: \(error.localizedDescription)")
                        } else {
                            print("Award added successfully")
                        }
                    }
                }
            }
    }
    
    private func updateUserStreaks(current: Int, max: Int) {
        guard let email = loggedUser?.email else { return }
        
        db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error searching user: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No users found with this email")
                    return
                }
                
                // Assuming email is unique, we take the first document
                if let userDoc = documents.first {
                    // Update the found document
                    userDoc.reference.updateData([
                        "totalStreak": current,
                        "maxStreak": max
                    ]) { error in
                        if let error = error {
                            print("Error updating streaks: \(error.localizedDescription)")
                        } else {
                            print("Streaks updated successfully")
                        }
                    }
                }
            }
    }
}

// MARK: - Subviews

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

struct StreakCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                Text(title)
                    .font(.subheadline)
            }
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AwardCard: View {
    let award: AwardsEarned
    var isEarned: Bool
    
    var body: some View {
        VStack {
            // Handle emoji or text image
            Text(award.awardImage)
                .font(.system(size: 70))
                .frame(width: 80, height: 80)
                .opacity(isEarned ? 1.0 : 0.6)

            Text(award.awardName)
                .font(.subheadline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 120)
                .foregroundColor(isEarned ? .primary : .gray)
            
            Text(award.description)
                .font(.caption)
                .foregroundColor(isEarned ? .gray : .gray.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(width: 120)

            if isEarned {
                Text(formatDate(award.dateEarned))
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("Not earned yet")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding()
        .background(isEarned ? Color.purple.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(15)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
