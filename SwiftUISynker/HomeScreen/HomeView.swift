import SwiftUI
import Foundation
import FirebaseFirestore

struct HomeView: View {
    @State private var selectedSegment: TaskViewType = .all
    @State private var selectedDate = Date()
    @State var loggedUser: User?
    @State private var expandedCategories: Set<Category> = []
    @State private var expandedPriorities: Set<Priority> = []
    @State private var isLoading: Bool = false
    let taskModel = TaskDataModel.shared
    
    // Start with empty task array
    @State var tasks: [UserTask] = []
    
    // Firebase reference
    private let db = Firestore.firestore()
    
    var body: some View {
        ScrollView (showsIndicators: false){
            // Header Section
            headerView()
            // Weekly Dates Picker
            weekView
            
            if isLoading {
                ProgressView("Loading tasks...")
                    .padding()
            } else {
                // Task List
                taskList
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            fetchUserTasks()
            print("🟣 Logged user in HomeView onAppear: \(String(describing: loggedUser))")
        }
    }
    
    // MARK: - Firebase Functions
    private func fetchUserTasks() {
        guard let user = loggedUser, !user.email.isEmpty else {
            print("❌ No logged user or email is empty")
            return
        }
        
        isLoading = true
        
        // Reference to tasks collection
        let tasksRef = db.collection("tasks")
        
        // Query tasks with matching userEmail
        tasksRef.whereField("userEmail", isEqualTo: user.email)
            .getDocuments { (querySnapshot, error) in
                isLoading = false
                
                if let error = error {
                    print("❌ Error getting documents: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                // Parse documents to UserTask objects
                var fetchedTasks: [UserTask] = []
                
                for document in documents {
                    let data = document.data()
                    
                    // Extract data from Firebase document
                    if let taskName = data["taskName"] as? String,
                       let description = data["description"] as? String,
                       let startTime = data["startTime"] as? String,
                       let endTime = data["endTime"] as? String,
                       let timestamp = data["date"] as? Timestamp,
                       let priorityString = data["priority"] as? String,
                       let alertString = data["alert"] as? String,
                       let categoryString = data["category"] as? String,
                       let isCompleted = data["isCompleted"] as? Bool {
                        
                        // Convert string values to enums
                        guard let priority = Priority(rawValue: priorityString),
                              let alert = Alert(rawValue: alertString),
                              let category = Category(rawValue: categoryString) else {
                            print("⚠️ Invalid enum value(s) for task: \(taskName)")
                            continue
                        }
                        
                        // Convert Firestore timestamp to Date
                        let date = timestamp.dateValue()
                        
                        // Create UserTask object
                        let task = UserTask(
                            taskName: taskName,
                            description: description,
                            startTime: startTime,
                            endTime: endTime,
                            date: date,
                            priority: priority,
                            alert: alert,
                            category: category,
                            otherCategory: data["otherCategory"] as? String,
                            isCompleted: isCompleted
                        )
                        
                        // If Firebase document has an ID field, you could assign it to task.id
                        if let idString = data["id"] as? String, let id = UUID(uuidString: idString) {
                            // Create a new task with the ID from Firebase
                            var updatedTask = task
                            updatedTask.id = id
                            fetchedTasks.append(updatedTask)
                        } else {
                            fetchedTasks.append(task)
                        }
                    }
                }
                
                // Update tasks array with fetched data
                self.tasks = fetchedTasks
                print("📊 Fetched \(fetchedTasks.count) tasks for user: \(user.email)")
            }
    }
    
    // MARK: - Header View
    @ViewBuilder
    private func headerView() -> some View {
        ZStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Hello, \(loggedUser?.name ?? "User")!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(selectedDate.fullFormattedString())
                }
                Spacer()
                CircularProgressView(percentage: progressPercentage)
                    .frame(width: 70, height: 80)
            }
            .padding(5)
        }
        .padding(.horizontal)
        .onAppear {
            print("📡 HeaderView loaded with user: \(loggedUser?.name ?? "nil")")
        }
    }

    
    private var progressPercentage: Int {
        let todayTasks = tasks.filter { $0.date.isSameDay(as: selectedDate) } // Filter today's tasks
        let completedTasks = todayTasks.filter { $0.isCompleted }.count // Count completed tasks
        let totalTasks = todayTasks.count
        
        return totalTasks > 0 ? Int((Double(completedTasks) / Double(totalTasks)) * 100) : 0
    }
    
    // MARK: - Week View
    private var weekView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Date().fullWeekDates(), id: \.self) { date in
                        VStack {
                            Text(date.formattedString(format: "d"))
                                .font(.headline)
                                .foregroundColor(selectedDate.isSameDay(as: date) ? .white : .black)

                            Text(date.formattedString(format: "E"))
                                .font(.subheadline)
                                .foregroundColor(selectedDate.isSameDay(as: date) ? .white : .gray)
                        }
                        .frame(width: 50, height: 70)
                        .background(selectedDate.isSameDay(as: date) ? Color.purple : Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .onTapGesture {
                            withAnimation {
                                selectedDate = date
                                proxy.scrollTo(date, anchor: .center) // Scroll when user selects a date
                            }
                        }
                        .id(date) // Assign ID for scrolling
                    }
                }
                .padding(.top, 20)
            }
            .onAppear {
                if let firstDate = Date().fullWeekDates().first(where: { $0.isSameDay(as: selectedDate) }) {
                    withAnimation{
                        proxy.scrollTo(firstDate, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Task List
    private var taskList: some View {
        VStack(alignment: .center) {
            HStack {
                Text("My Tasks")
                    .font(.title.bold())

                Spacer()

                Text("\(completedTaskCount)/\(totalTaskCount)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(20)
            }
            .padding()

            segemntedTasks
        }
    }

    // MARK: - Task Count Computation
    private var completedTaskCount: Int {
        let todayTasks = tasks.filter { $0.date.isSameDay(as: selectedDate) }
        return todayTasks.filter { $0.isCompleted }.count
    }

    private var totalTaskCount: Int {
        return tasks.filter { $0.date.isSameDay(as: selectedDate) }.count
    }
    
    private var segemntedTasks: some View {
        VStack {
            // MARK: - Segmented Picker
            Picker("View Type", selection: $selectedSegment) {
                Text("All").tag(TaskViewType.all)
                Text("Category").tag(TaskViewType.category)
                Text("Priority").tag(TaskViewType.priority)
                Text("Overdue").tag(TaskViewType.overdue)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom)
            // MARK: - Content Based on Selection
            switch selectedSegment {
            case .all:
                allTasksView
            case .category:
                categoryView
            case .priority:
                priorityView
            case .overdue:
                overdueTasksView
            }
            
            Spacer()
        }
    }
    
    // MARK: - All Tasks View
    private var allTasksView: some View {
        VStack {
            let todayTasks = tasks.filter { $0.date.isSameDay(as: selectedDate) }
                .sorted { first, second in
                    if !first.isCompleted && second.isCompleted {
                        return true
                    } else if first.isCompleted && !second.isCompleted {
                        return false
                    } else {
                        // Compare by start time
                        guard let firstTime = Date.fromTimeString(first.startTime),
                              let secondTime = Date.fromTimeString(second.startTime) else {
                            return false
                        }
                        return firstTime < secondTime
                    }
                }
            
            if todayTasks.isEmpty {
                Image("notaskimage")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else {
                ForEach(todayTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task, loggedUser: loggedUser)) {
                        TaskRow(task: task)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Category View
    private var categoryView: some View {
        VStack(spacing: 10) {
            let tasksForSelectedDate = tasks.filter { $0.date.isSameDay(as: selectedDate) }
            
            if tasksForSelectedDate.isEmpty {
                Text("No tasks available")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(Category.allCases, id: \.self) { category in
                    let categoryTasks = tasksForSelectedDate.filter { $0.category == category }
                    
                    if !categoryTasks.isEmpty {
                        VStack {
                            // Header Button for Expand/Collapse
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.3)) {
                                    if expandedCategories.contains(category) {
                                        expandedCategories.remove(category)
                                    } else {
                                        expandedCategories.insert(category)
                                    }
                                }
                            }) {
                                HStack {
                                    Text(category.rawValue)
                                        .font(.title3.bold())
                                        .foregroundColor(Color(category.customCategory.categoryColor))
                                    
                                    Spacer()
                                    
                                    Text("\(categoryTasks.count)")
                                        .padding(8)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                    
                                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                                        .foregroundColor(Color(category.customCategory.categoryColor))
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                            }
                            
                            // Expandable Content
                            if expandedCategories.contains(category) {
                                VStack(alignment: .leading, spacing: 5) {
                                    ForEach(categoryTasks) { task in
                                        NavigationLink(destination: TaskDetailView(task: task, loggedUser: loggedUser)) {
                                            TaskRow(task: task)
                                                .padding(.vertical, 3)
                                                .transition(.move(edge: .top).combined(with: .opacity))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.leading, 10)
                            }
                        }
                        .padding(.horizontal,5)
                    }
                }
            }
        }
    }

    // MARK: - Priority View
    private var priorityView: some View {
        VStack(spacing: 10) {
            let tasksForSelectedDate = tasks.filter { $0.date.isSameDay(as: selectedDate) }
            
            if tasksForSelectedDate.isEmpty {
                Text("No tasks available")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(Priority.allCases, id: \.self) { priority in
                    let priorityTasks = tasksForSelectedDate.filter { $0.priority == priority }
                    
                    if !priorityTasks.isEmpty {
                        VStack {
                            // Header Button for Expand/Collapse
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.3)) {
                                    if expandedPriorities.contains(priority) {
                                        expandedPriorities.remove(priority)
                                    } else {
                                        expandedPriorities.insert(priority)
                                    }
                                }
                            }) {
                                HStack {
                                    Text(priority.rawValue)
                                        .font(.title3.bold())
                                        .foregroundColor(Color(priority.tintColor))
                                    
                                    Spacer()
                                    
                                    Text("\(priorityTasks.count)")
                                        .padding(8)
                                        .background(Color.purple)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                    
                                    Image(systemName: expandedPriorities.contains(priority) ? "chevron.down" : "chevron.right")
                                        .foregroundColor(Color(priority.tintColor))
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                            }
                            
                            // Expandable Content
                            if expandedPriorities.contains(priority) {
                                VStack(alignment: .leading, spacing: 5) {
                                    ForEach(priorityTasks) { task in
                                        NavigationLink(destination: TaskDetailView(task: task, loggedUser: loggedUser)) {
                                            TaskRow(task: task)
                                                .padding(.vertical, 3)
                                                .transition(.move(edge: .top).combined(with: .opacity))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.leading, 10)
                            }
                        }
                        .padding(.horizontal,5)
                    }
                }
            }
        }
    }

    // MARK: - Overdue Tasks View
    private var overdueTasksView: some View {
        VStack {
            if let user = loggedUser {
                // For overdue tasks, we'll use the tasks we fetched from Firebase
                let now = Date()
                let overdueTasks = tasks.filter { task in
                    // A task is overdue if its date is before today AND it's not completed
                    !task.isCompleted && Calendar.current.startOfDay(for: task.date) < Calendar.current.startOfDay(for: now)
                }
                
                if overdueTasks.isEmpty {
                    Text("No overdue tasks 🎉")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(overdueTasks) { task in
                        NavigationLink(destination: OverdueDetailsView(loggedUser: loggedUser, task: task)) {
                            TaskRow(task: task)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                Text("No logged user 👦")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}

// MARK: - Enums
enum TaskViewType {
    case all, category, priority, overdue
}

// MARK: - Preview
#Preview {
    NavigationStack{
        HomeView()
    }
}
