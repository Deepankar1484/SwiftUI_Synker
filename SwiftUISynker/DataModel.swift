import UIKit
import Firebase
import FirebaseFirestore

import Foundation

extension Date {
    // Fetches the full week (Sunday to Saturday) for the current date.
    func fullWeekDates() -> [Date] {
//        let calendar = Calendar.current
//        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: self)?.start ?? self
//        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        
// MARK: - if used commented on u will get full month array and above will give week by week.
        
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: self) else { return [] }
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
        
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    // Formats a Date into a readable string (e.g., "16 Mar, Sun").
    func formattedString(format: String = "dd MMM, EEE") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    func fullFormattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    func yearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: self)
    }
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
    // Converts Date to a time string (e.g., "10:30 AM").
    func timeString(format: String = "hh:mm a") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    // Converts a time string (e.g., "10:30 AM") to a Date.
    static func fromTimeString(_ timeString: String, format: String = "hh:mm a") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: timeString)
    }
}

func getMarch17Date() -> Date {
    let calendar = Calendar.current
    var dateComponents = DateComponents()
    dateComponents.year = calendar.component(.year, from: Date()) // Current year
    dateComponents.month = 3
    dateComponents.day = 20

    return calendar.date(from: dateComponents) ?? Date() // Fallback to current date if nil
}

func getMarchDate(day: Int) -> Date {
    let calendar = Calendar.current
    var dateComponents = DateComponents()
    dateComponents.year = calendar.component(.year, from: Date()) // Use the current year
    dateComponents.month = 3
    dateComponents.day = day

    return calendar.date(from: dateComponents) ?? Date() // Fallback to current date if nil
}

func getAprilDate(day: Int) -> Date {
    let calendar = Calendar.current
    var dateComponents = DateComponents()
    dateComponents.year = calendar.component(.year, from: Date()) // Use the current year
    dateComponents.month = 4
    dateComponents.day = day
    
    return calendar.date(from: dateComponents) ?? Date() // Fallback to current date if nil
}

// MARK: - Enums

// MARK: - Models
struct User {
    var userId: UUID = UUID()
    var name: String
    var email: String
    var password: String
    var phone: String?
    var taskIds: [UUID] = []
    var timeCapsuleIds: [UUID] = []
    var totalStreak: Int = 0
    var maxStreak: Int = 0
    var settings: Settings?
    var awardsEarned: [AwardsEarned] = []
    var lastDateModified: Date = Date()
    
    init(name: String, email: String, password: String) {
        self.name = name
        self.email = email
        self.password = password
    }
}

struct AwardsEarned: Identifiable{
    var id: UUID
    var awardName: String
    var description: String
    var awardImage: String
    var dateEarned: Date
    
    
    init(id: UUID = UUID(), awardName: String,description: String,awardImage: String, dateEarned: Date) {
        self.id = id
        self.awardName = awardName
        self.dateEarned = dateEarned
        self.description = description
        self.awardImage = awardImage
    }
}

struct Settings {
    var profilePicture: String?
    var usage: Usage
    var bedtime: String
    var wakeUpTime: String
    var notificationsEnabled: Bool
}


enum Usage: String,CaseIterable {
    case personal = "Personal"
    case work = "Work"
    case education = "Education"
}

struct UserTask: Identifiable {
    var id = UUID()
    var taskName: String
    var description: String
    var startTime: String
    var endTime: String
    var date: Date // Single date for the task
    var priority: Priority
    var isCompleted: Bool
    var alert: Alert
    var category: Category
    var otherCategory: String?
    
    init(taskName: String, description: String, startTime: String, endTime: String, date: Date, priority: Priority, alert: Alert, category: Category, otherCategory: String? = nil, isCompleted: Bool = false) {
        self.taskName = taskName
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.date = date
        self.priority = priority
        self.isCompleted = isCompleted
        self.alert = alert
        self.category = category
        self.otherCategory = otherCategory
    }
    mutating func markAsCompleted() {
        self.isCompleted = true
    }
}

enum Priority: String,CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var tintColor: UIColor {
        switch self {
        case .low: return .systemGreen
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

enum Alert: String,CaseIterable {
    case none = "None"
    case fiveMinutes = "5 minutes"
    case tenMinutes = "10 minutes"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case oneHour = "1 hour"
}



enum Category: String, CaseIterable {
    case sports = "Sports"
    case study = "Study"
    case work = "Work"
    case meetings = "Meetings"
    case habits = "Habits"
    case gym = "Gym"
    case relax = "Relax"
    case others = "Others"
    
    
    var customCategory: CustomCategory {
        switch self {
        case .sports:
            return CustomCategory(
                category: self,
                categoryName: "Sports",
                categoryColor: UIColor.systemBlue,
                insights: """
                1. Regular physical activity improves mental and physical health.
                2. Strength training builds muscle and boosts metabolism.
                3. Cardiovascular exercises like running enhance heart health.
                4. Playing team sports helps develop communication and leadership skills.
                """
            )
        case .study:
            return CustomCategory(
                category: self,
                categoryName: "Study",
                categoryColor: UIColor.systemGreen,
                insights: """
                1. Active recall is more effective than passive reading.
                2. Spaced repetition improves long-term retention.
                3. Mind mapping helps visualize and connect complex concepts.
                4. Regular breaks improve focus and prevent burnout.
                """
            )
        case .work:
            return CustomCategory(
                category: self,
                categoryName: "Work",
                categoryColor: UIColor.systemRed,
                insights: """
                1. Prioritizing tasks with the Eisenhower Matrix boosts productivity.
                2. Effective time management leads to better work-life balance.
                3. Delegation of tasks reduces stress and increases efficiency.
                4. Regular feedback helps improve skills and professional growth.
                """
            )
        case .meetings:
            return CustomCategory(
                category: self,
                categoryName: "Meetings",
                categoryColor: UIColor.systemOrange,
                insights: """
                1. Setting a clear agenda leads to more productive meetings.
                2. Short, focused meetings prevent wasted time.
                3. Active listening improves communication and collaboration.
                4. Following up with action items ensures tasks are completed.
                """
            )
        case .habits:
            return CustomCategory(
                category: self,
                categoryName: "Habits",
                categoryColor: UIColor.systemPurple,
                insights: """
                1. Habit stacking helps integrate new routines effortlessly.
                2. Consistency is more important than intensity for habit formation.
                3. Tracking progress increases motivation and commitment.
                4. Breaking bad habits requires replacing them with positive alternatives.
                """
            )
        case .gym:
            return CustomCategory(
                category: self,
                categoryName: "Gym",
                categoryColor: UIColor.systemYellow, // Consider using blue for a fitness-related theme
                insights: """
                1. Progressive overload is key to building strength and muscle.
                2. Proper form is more important than lifting heavier weights.
                3. Rest and recovery are essential for muscle growth and injury prevention.
                4. Nutrition plays a crucial role in fitness progress.
                """
            )
        case .relax:
            return CustomCategory(
                category: self,
                categoryName: "Relax",
                categoryColor: UIColor.systemTeal, // A fun and vibrant color for entertainment
                insights: """
                1. Taking breaks with entertainment boosts creativity and reduces stress.
                2. Balance is key—too much screen time can affect productivity and sleep.
                3. Engaging in different forms of entertainment (movies, music, books) enhances well-being.
                4. Social entertainment, like games or events, strengthens relationships and teamwork.
                """
            )
        case .others:
            return CustomCategory(
                category: self,
                categoryName: "Others",
                categoryColor: UIColor.systemGray,
                insights: """
                1. Miscellaneous tasks should be grouped for better organization.
                2. Keeping a to-do list helps track small but important tasks.
                3. Time-blocking ensures even unstructured work is completed.
                4. Prioritization prevents low-impact tasks from taking up too much time.
                """
            )
        }
    }
    var taskImage: String {
        switch self {
        case .work: return "latch.2.case"
        case .study: return "books.vertical"
        case .sports: return "figure.run"
        case .meetings: return "person.line.dotted.person"
        case .habits: return "arrow.triangle.2.circlepath"
        case .gym: return "dumbbell"
        case .relax: return "film.fill"
        case .others: return "Others"
        }
    }
}

struct CustomCategory {
    var category: Category
    var categoryName: String?
    var categoryColor: UIColor
    var insights: String
}


struct TimeCapsule: Identifiable {
    var id = UUID()
    var capsuleName: String
    var deadline: Date
    var priority: Priority
    var description: String
    var completionPercentage: Double
    var category: Category
    var subtaskIds: [UUID] // Store subtask IDs instead of full subtasks
    
    init(capsuleName: String, deadline: Date, priority: Priority, description: String, category: Category) {
        self.capsuleName = capsuleName
        self.deadline = deadline
        self.priority = priority
        self.description = description
        self.completionPercentage = 0.0
        self.category = category
        self.subtaskIds = []
    }
    
    // Calculate completion percentage based on completed subtasks
    mutating func updateCompletionPercentage(subtasks: [Subtask]) {
        if subtasks.isEmpty {
            completionPercentage = 0.0
            return
        }
        
        let completedCount = subtasks.filter { $0.isCompleted }.count
        completionPercentage = Double(completedCount) / Double(subtasks.count) * 100.0
    }
}

struct Subtask {
    var subtaskId: UUID
    var subtaskName: String
    var description: String
    var isCompleted: Bool
    
    init(subtaskId: UUID = UUID(), subtaskName: String, description: String, isCompleted: Bool = false) {
        self.subtaskId = subtaskId
        self.subtaskName = subtaskName
        self.description = description
        self.isCompleted = isCompleted
    }
    
    mutating func markAsCompleted() {
        self.isCompleted = true
    }
}

struct Award { //these are the awards that we have.
    var id = UUID()
    var awardName: String
    var description: String
    
    init(awardName: String, description: String) {
        self.awardName = awardName
        self.description = description
    }
}


class TaskDataModel {
    // Singleton instance
    static let shared = TaskDataModel()
    
    // Private properties
    private var users: [User] = []
    private var tasks: [UserTask] = []
    private var timeCapsules: [TimeCapsule] = []
    private var subtasks: [Subtask] = []
    private var awards: [Award] = []
    private var currentUser: User?
    
    // Private initializer for singleton
    private init() {
        setupSampleData()
    }
    
    // MARK: - User Management
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func getUser(by userId: UUID) -> User? {
        return users.first { $0.userId == userId }
    }
    
    func userExists(email: String) -> Bool {
        return users.contains { $0.email == email }
    }
    
    func validateUser(email: String, password: String) -> User? {
        let user = users.first { $0.email == email && $0.password == password }
        if user != nil {
            currentUser = user
        }
        return user
    }
    
    func addUser(_ newUser: User) -> Bool {
        if userExists(email: newUser.email) {
            print("Error: User with email \(newUser.email) already exists.")
            return false
        }
        users.append(newUser)
        print("User with email \(newUser.email) added successfully.")
        return true
    }
    
    func updateUser(_ user: User) {
        if let index = users.firstIndex(where: { $0.userId == user.userId }) {
            users[index] = user
            
            // If the updated user is the current user, update currentUser reference
            if currentUser?.userId == user.userId {
                currentUser = user
            }
        }
    }
    /*
    
    func updateStreak(for userId: UUID) {
        guard var user = getUser(by: userId) else { return }
        let today = Date()
        let calendar = Calendar.current

        // Check if it's a new month
        if let lastModifiedMonth = calendar.dateComponents([.year, .month], from: user.lastDateModified).month,
           let todayMonth = calendar.dateComponents([.year, .month], from: today).month,
           let lastModifiedYear = calendar.dateComponents([.year], from: user.lastDateModified).year,
           let todayYear = calendar.dateComponents([.year], from: today).year,
           (todayMonth != lastModifiedMonth || todayYear != lastModifiedYear) {
            
            // Award user if they were consistent last month
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: today)!
            let range = calendar.range(of: .day, in: .month, for: previousMonth)!
            let totalDaysLastMonth = range.count
            
            let tasksCompletedAllDays = (1...totalDaysLastMonth).allSatisfy { day in
                if let date = calendar.date(from: DateComponents(year: todayYear, month: todayMonth - 1, day: day)) {
                    let tasks = getTasksByDate(for: userId, date: date)
                    return !tasks.isEmpty && tasks.allSatisfy { $0.isCompleted }
                }
                return false
            }

            if tasksCompletedAllDays {
                awardUserForMonth(userId: user.userId, month: lastModifiedMonth, year: lastModifiedYear)
                // update the user to new user as the award is earned
                if let updatedUser = getUser(by: user.userId) {
                    user = updatedUser
                }
            }
            // Reset streak for the new month
            user.totalStreak = 0
            user.maxStreak = 0
        }

        // Skip update if already done today
        if user.lastDateModified.isSameDay(as: today) { return }

        // Update streak for the current month
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        var currentDate = max(user.lastDateModified, startOfMonth)

        while let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate), nextDate <= today {
            let tasksForTheDay = getTasksByDate(for: userId, date: currentDate)
            let allCompleted = !tasksForTheDay.isEmpty && tasksForTheDay.allSatisfy { $0.isCompleted }
            if allCompleted {
                user.totalStreak += 1
                user.maxStreak = max(user.maxStreak, user.totalStreak)
            } else {
                user.totalStreak = 0 // Reset streak if any task is incomplete
            }
            currentDate = nextDate
        }

        // Update last modified date to today
        user.lastDateModified = today
        updateUser(user)
    }
    */
    func deleteUser(_ userId: UUID) -> Bool {
        if let index = users.firstIndex(where: { $0.userId == userId }) {

            // Remove all tasks and time capsules associated with the user
            deleteTasks(for: userId)
            deleteTimeCapsules(for: userId)

            // Remove the user
            users.remove(at: index)
            // If the deleted user is the current user, log them out
            if currentUser?.userId == userId {
                currentUser = nil
            }
            return true
        }
        return false
    }
    
    func deleteTasks(for userId: UUID) {
        if let user = users.first(where: { $0.userId == userId }) {
            tasks.removeAll { user.taskIds.contains($0.id) }
//            print("All tasks for user \(userId) have been deleted.")
        }
    }
    
    func deleteTimeCapsules(for userId: UUID) {
        if let user = users.first(where: { $0.userId == userId }) {
            timeCapsules.removeAll { user.timeCapsuleIds.contains($0.id) }
//            print("All time capsules for user \(userId) have been deleted.")
        }
    }

    // MARK: - Task Management
    func getAllTasks(for userId: UUID) -> [UserTask] {
        return tasks.filter { task in
            if let user = getUser(by: userId) {
                return user.taskIds.contains(task.id)
            }
            return false
        }
    }
    
    func getTask(by taskId: UUID) -> UserTask? {
        return tasks.first { $0.id == taskId }
    }
    
    func addTask(_ task: UserTask, for userId: UUID) -> Bool {
        guard let userIndex = users.firstIndex(where: { $0.userId == userId }) else {
            print("Error: User not found with ID \(userId).")
            return false
        }
        // Add task to the tasks array
        tasks.append(task)
        
        // Update the user's taskIds array
        users[userIndex].taskIds.append(task.id)
        
        // Update current user if needed
        if currentUser?.userId == userId {
            currentUser?.taskIds.append(task.id)
        }
        
        return true
    }
    
    func updateTask(_ task: UserTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    // Add to the Task Management section
    func markTaskAsComplete(taskId: UUID) -> Bool {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskId }) else {
            print("Error: Task not found with ID \(taskId).")
            return false
        }
        // Update the task's completion status
        tasks[taskIndex].isCompleted = true
        return true
    }
    
    func deleteTask(with taskId: UUID, for userId: UUID) -> Bool {
        guard let userIndex = users.firstIndex(where: { $0.userId == userId }) else {
            print("Error: User not found with ID \(userId).")
            return false
        }
        
        // Remove the task from the tasks array
        tasks.removeAll { $0.id == taskId }
        
        // Remove the taskId from the user's taskIds array
        users[userIndex].taskIds.removeAll { $0 == taskId }
        
        // Update current user if needed
        if currentUser?.userId == userId {
            currentUser?.taskIds.removeAll { $0 == taskId }
        }
        
        return true
    }
    
    func getTasksByDate(for userId: UUID, date: Date) -> [UserTask] {
        return getAllTasks(for: userId).filter { task in
            let calendar = Calendar.current
            return calendar.isDate(task.date, inSameDayAs: date)
        }
    }
    
    func getTasksByCategory(for userId: UUID, category: Category) -> [UserTask] {
        return getAllTasks(for: userId).filter { $0.category == category }
    }
    
    func getTasksByPriority(for userId: UUID, priority: Priority) -> [UserTask] {
        return getAllTasks(for: userId).filter { $0.priority == priority }
    }
    
    func getCompletedTasks(for userId: UUID) -> [UserTask] {
        return getAllTasks(for: userId).filter { $0.isCompleted }
    }
    
    func getPendingTasks(for userId: UUID) -> [UserTask] {
        return getAllTasks(for: userId).filter { !$0.isCompleted }
    }
    
    func fetchOverdueTasks(for userId: UUID) -> [UserTask] {
        let today = Calendar.current.startOfDay(for: Date())
        return getAllTasks(for: userId).filter { $0.date < today && !$0.isCompleted }
    }
    
    
    func getAllTimeCapsules(for userId: UUID) -> [TimeCapsule] {
            return timeCapsules.filter { capsule in
                if let user = getUser(by: userId) {
                    return user.timeCapsuleIds.contains(capsule.id)
                }
                return false
            }
    }



    
    func getTimeCapsule(by capsuleId: UUID) -> TimeCapsule? {
        return timeCapsules.first { $0.id == capsuleId }
    }
    
    func addTimeCapsule(_ capsule: TimeCapsule, for userId: UUID) -> Bool {
        guard let userIndex = users.firstIndex(where: { $0.userId == userId }) else {
            print("Error: User not found with ID \(userId).")
            return false
        }
        
        // Add capsule to the timeCapsules array
        timeCapsules.append(capsule)
        
        // Update the user's timeCapsuleIds array
        users[userIndex].timeCapsuleIds.append(capsule.id)
        
        // Update current user if needed
        if currentUser?.userId == userId {
            currentUser?.timeCapsuleIds.append(capsule.id)
        }
        
        return true
    }
    
    func updateTimeCapsule(_ capsule: TimeCapsule) {
        if let index = timeCapsules.firstIndex(where: { $0.id == capsule.id }) {
            timeCapsules[index] = capsule
        }
    }
    
    func deleteTimeCapsule(with capsuleId: UUID, for userId: UUID) -> Bool {
        guard let userIndex = users.firstIndex(where: { $0.userId == userId }) else {
            print("Error: User not found with ID \(userId).")
            return false
        }
        
        // Remove the capsule from the timeCapsules array
        timeCapsules.removeAll { $0.id == capsuleId }
        
        // Remove the capsuleId from the user's timeCapsuleIds array
        users[userIndex].timeCapsuleIds.removeAll { $0 == capsuleId }
        
        // Update current user if needed
        if currentUser?.userId == userId {
            currentUser?.timeCapsuleIds.removeAll { $0 == capsuleId }
        }
        
        return true
    }
    
    // MARK: - Subtask Management
    
    func getSubtasks(for capsuleId: UUID) -> [Subtask] {
            if let capsule = getTimeCapsule(by: capsuleId) {
                return subtasks.filter { subtask in
                    capsule.subtaskIds.contains(subtask.subtaskId)
                }
            }
            return []
    }
    
    
    func getSubtask(by subtaskId: UUID) -> Subtask? {
        return subtasks.first { $0.subtaskId == subtaskId }
    }
    
    func addSubtask(_ subtask: Subtask, to capsuleId: UUID) -> Bool {
        guard let capsuleIndex = timeCapsules.firstIndex(where: { $0.id == capsuleId }) else {
            print("Error: Time Capsule not found with ID \(capsuleId).")
            return false
        }
        
        // Add subtask to the subtasks array
        subtasks.append(subtask)
        
        // Update the capsule's subtaskIds array
        timeCapsules[capsuleIndex].subtaskIds.append(subtask.subtaskId)
        
        // Update the completion percentage
        let capsuleSubtasks = getSubtasks(for: capsuleId)
        timeCapsules[capsuleIndex].updateCompletionPercentage(subtasks: capsuleSubtasks)
        
        return true
    }
    
    func updateSubtask(_ subtask: Subtask, in capsuleId: UUID) {
        if let subtaskIndex = subtasks.firstIndex(where: { $0.subtaskId == subtask.subtaskId }) {
            subtasks[subtaskIndex] = subtask
            
            // Update the completion percentage of the associated capsule
            if let capsuleIndex = timeCapsules.firstIndex(where: { $0.id == capsuleId }) {
                let capsuleSubtasks = getSubtasks(for: capsuleId)
                timeCapsules[capsuleIndex].updateCompletionPercentage(subtasks: capsuleSubtasks)
            }
        }
    }
    
    func markSubtaskComplete(subtaskId: UUID, capsuleId: UUID) -> Bool {
        // Find the subtask
        guard let subtaskIndex = subtasks.firstIndex(where: { $0.subtaskId == subtaskId }) else {
            print("Error: Subtask not found with ID \(subtaskId).")
            return false
        }
        
        // Find the time capsule
        guard let capsuleIndex = timeCapsules.firstIndex(where: { $0.id == capsuleId }) else {
            print("Error: Time Capsule not found with ID \(capsuleId).")
            return false
        }
        
        // Verify that the subtask belongs to the specified time capsule
        guard timeCapsules[capsuleIndex].subtaskIds.contains(subtaskId) else {
            print("Error: Subtask with ID \(subtaskId) does not belong to Time Capsule with ID \(capsuleId).")
            return false
        }
        
        // Mark the subtask as completed
        subtasks[subtaskIndex].isCompleted = true
        
        // Update the completion percentage of the time capsule
        let capsuleSubtasks = getSubtasks(for: capsuleId)
        timeCapsules[capsuleIndex].updateCompletionPercentage(subtasks: capsuleSubtasks)
        
//        print("Subtask marked as complete and time capsule percentage updated.")
        return true
    }
    
    func deleteSubtask(with subtaskId: UUID, from capsuleId: UUID) -> Bool {
        guard let capsuleIndex = timeCapsules.firstIndex(where: { $0.id == capsuleId }) else {
            print("Error: Time Capsule not found with ID \(capsuleId).")
            return false
        }
        
        // Remove the subtask from the subtasks array
        subtasks.removeAll { $0.subtaskId == subtaskId }
        
        // Remove the subtaskId from the capsule's subtaskIds array
        timeCapsules[capsuleIndex].subtaskIds.removeAll { $0 == subtaskId }
        
        // Update the completion percentage
        let capsuleSubtasks = getSubtasks(for: capsuleId)
        timeCapsules[capsuleIndex].updateCompletionPercentage(subtasks: capsuleSubtasks)
        
        return true
    }
     
    
    // MARK: - Award Management
    
    /*
    
    func getAllAwards() -> [Award] {
        return awards
    }
    
    func getAward(by awardId: UUID) -> Award? {
        return awards.first { $0.id == awardId }
    }
    
    func getUserAwards(for userId: UUID) -> [Award] {
        if let user = getUser(by: userId) {
            return user.awardsEarned.compactMap { earned in
                getAward(by: earned.awardId)
            }
        }
        return []
    }
    
    func awardUser(userId: UUID, awardId: UUID) -> Bool {
        guard let userIndex = users.firstIndex(where: { $0.userId == userId }) else {
            print("Error: User not found with ID \(userId).")
            return false
        }
        
        guard getAward(by: awardId) != nil else {
            print("Error: Award not found with ID \(awardId).")
            return false
        }
        
        // Create a new AwardsEarned instance
        let newAward = AwardsEarned(awardId: awardId, dateEarned: Date())
        
        // Add it to the user's awardsEarned array
        users[userIndex].awardsEarned.append(newAward)
        
        // Update current user if needed
        if currentUser?.userId == userId {
            currentUser?.awardsEarned.append(newAward)
        }
        
        return true
    }
    
    func awardUserForMonth(userId: UUID, month: Int, year: Int) {
        let monthAwardName = "Perfect Month \(year)-\(month)"
        let monthAwardDescription = "Completed all tasks for \(month)-\(year)"
        
        // Check if the award already exists
        if let existingAward = awards.first(where: { $0.awardName == monthAwardName }) {
            _ = awardUser(userId: userId, awardId: existingAward.id)
        } else {
            // Create a new award
            let newAward = Award(awardName: monthAwardName, description: monthAwardDescription)
            awards.append(newAward)
            _ = awardUser(userId: userId, awardId: newAward.id)
        }
    }
    */
    
    // MARK: - Helper Methods
    
    func getTodayDayIndex() -> Int {
        let today = Date()
        let calendar = Calendar.current
        // Get the weekday as a number (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        let weekday = calendar.component(.weekday, from: today)
        // Adjust to make Sunday = 0, Monday = 1, ..., Saturday = 6
        return weekday - 1
    }
    
    // MARK: - Private Methods
    
    func addCompletedTasksForMarch(userId: UUID) {
        for day in 1...31 {
            let taskDate = getMarchDate(day: day) // Directly use the returned Date

            let completedTask = UserTask(
                taskName: "Daily March Task",
                description: "Completed a task on March \(day).",
                startTime: "08:00 AM",
                endTime: "08:30 AM",
                date: taskDate,
                priority: .low,
                alert: .none,
                category: .others,
                isCompleted: true
            )
            _ = addTask(completedTask, for: userId)
        }
    }
    
    private func setupSampleData() {
        // Sample awards
        let award1 = Award(awardName: "Welcome Badge", description: "Small wins lead to big success! Keep completing tasks and earning more badges.")
//        let award2 = Award(awardName: "5-Day Streak", description: "Completed tasks for 5 consecutive days")
//        let award3 = Award(awardName: "Time Master", description: "Completed 1 time capsule")
//        let award4 = Award(awardName: "Time Master", description: "Completed 5 time capsule")
        
        awards = [award1]
        
        // Sample user
        let sampleSettings = Settings(
            profilePicture: "person.fill",
            usage: .personal,
            bedtime: "22:00 PM",
            wakeUpTime: "06:00 AM",
            notificationsEnabled: true
        )
        
        let sampleUser = User(
            name: "John Doe",
            email: "a@gmail.com",
            password: "123456"
           
        )
        
        users.append(sampleUser)
        
        // Sample tasks
        let task1 = UserTask(
            taskName: "Morning Workout",
            description: "30-minute cardio session",
            startTime: "06:00 AM",
            endTime: "06:30 AM",
            date: Date(),
            priority: .low,
            alert: .fiveMinutes,
            category: .sports,
            isCompleted: true
        )
        
        let task2 = UserTask(
            taskName: "Team Meeting",
            description: "Weekly project status update",
            startTime: "10:00 AM",
            endTime: "11:00 PM",
            date: Date(),
            priority: .medium,
            alert: .tenMinutes,
            category: .meetings
        )
        
        let task3 = UserTask(
            taskName: "Project Work",
            description: "Weekly project status update",
            startTime: "10:00 PM",
            endTime: "11:00 PM",
            date: getAprilDate(day: 1),
            priority: .medium,
            alert: .tenMinutes,
            category: .others,
            isCompleted: true
        )
        
        let task4 = UserTask(
            taskName: "Lunch Break",
            description: "Have a healthy meal and relax",
            startTime: "01:00 PM",
            endTime: "01:30 PM",
            date: getAprilDate(day: 1),
            priority: .low,
            alert: .none,
            category: .habits,
            isCompleted: true
        )
        
        let task5 = UserTask(
            taskName: "Code Review",
            description: "Review pull requests and provide feedback",
            startTime: "03:00 PM",
            endTime: "04:00 PM",
            date: getMarchDate(day: 30),
            priority: .high,
            alert: .fifteenMinutes,
            category: .meetings,
            isCompleted: true
        )
        
        let task6 = UserTask(
            taskName: "Evening Jog",
            description: "Run 5km in the park",
            startTime: "06:30 PM",
            endTime: "07:00 PM",
            date: getMarchDate(day: 30),
            priority: .medium,
            alert: .tenMinutes,
            category: .sports,
            isCompleted: true
        )
        
        let task7 = UserTask(
            taskName: "Read a Book",
            description: "Read at least 20 pages of a self-improvement book",
            startTime: "09:00 PM",
            endTime: "09:30 PM",
            date: getMarchDate(day: 27),
            priority: .low,
            alert: .fiveMinutes,
            category: .habits,
            isCompleted: true
        )

        
        // Add tasks to the sample user
        _ = addTask(task1, for: sampleUser.userId)
        _ = addTask(task2, for: sampleUser.userId)
        _ = addTask(task3, for: sampleUser.userId)
        _ = addTask(task4, for: sampleUser.userId)
        _ = addTask(task5, for: sampleUser.userId)
        _ = addTask(task6, for: sampleUser.userId)
        _ = addTask(task7, for: sampleUser.userId)
        
        addCompletedTasksForMarch(userId: sampleUser.userId)
        
        
       
        
        // Sample time capsule
        let capsule1 = TimeCapsule(
            capsuleName: "Learn Swift",
            deadline: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            priority: .low,
            description: "Master Swift programming language basics",
            category: .study
        )
        let capsule2 = TimeCapsule(
            capsuleName: "Complete the iOS project",
            deadline: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
            priority: .high,
            description: "Complete the iOS Project and submit to Apple. Master Swift programming language basics.",
            category: .work
        )
        let capsule3 = TimeCapsule(
            capsuleName: "Bhangra Performance",
            deadline: Calendar.current.date(byAdding: .day, value: 60, to: Date())!,
            priority: .medium,
            description: "I need to perform in marriage ceremony. So I need to learn Bhangra and perform.",
            category: .others
        )
        
        _ = addTimeCapsule(capsule1, for: sampleUser.userId)
        _ = addTimeCapsule(capsule2, for: sampleUser.userId)
        _ = addTimeCapsule(capsule3, for: sampleUser.userId)
        
        // Sample subtasks for the time capsule 1
        let subtask1 = Subtask(subtaskName: "Learn variables and constants", description: "We will learn about variables and constants.")
        let subtask2 = Subtask(subtaskName: "Learn data types", description: "We will learn about data Type.")
        let subtask3 = Subtask(subtaskName: "Learn control flow", description: "We will learn about control flow.")
        
        _ = addSubtask(subtask1, to: capsule1.id)
        _ = addSubtask(subtask2, to: capsule1.id)
        _ = addSubtask(subtask3, to: capsule1.id)
        
        
        // Sample subtasks for the time capsule 2
        let subtask4 = Subtask(subtaskName: "CRUD operations for task", description: "Complete CRUD operations for task.",isCompleted: true)
        let subtask5 = Subtask(subtaskName: "Read operations for capsule", description: "Complete Read operations for Capsule.",isCompleted: true)
        let subtask6 = Subtask(subtaskName: "CRUD operations for capsule", description: "Complete CRUD operations for Capsule.")
        let subtask7 = Subtask(subtaskName: "Awards Screen and awarding part", description: "Complete Awards Screen and awarding part.")
        _ = addSubtask(subtask4, to: capsule2.id)
        _ = addSubtask(subtask5, to: capsule2.id)
        _ = addSubtask(subtask6, to: capsule2.id)
        _ = addSubtask(subtask7, to: capsule2.id)
        
        // Sample subtasks for the time capsule 3
        let subtask8 = Subtask(subtaskName: "Song 1", description: "Performance on Song 1.",isCompleted: true)
        let subtask9 = Subtask(subtaskName: "Song 2", description: "Performance on Song 2.",isCompleted: true)
        _ = addSubtask(subtask8, to: capsule3.id)
        _ = addSubtask(subtask9, to: capsule3.id)
        
        
        // Award the user
        
    }
}
