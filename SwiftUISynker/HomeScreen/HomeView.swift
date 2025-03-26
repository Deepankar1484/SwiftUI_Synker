import SwiftUI
import Foundation

struct HomeView: View {
    @State private var selectedSegment: TaskViewType = .all
    @State private var selectedDate = Date()
    @State var loggedUser: User?
    @State private var expandedCategories: Set<Category> = []
    @State private var expandedPriorities: Set<Priority> = []
    let taskModel = TaskDataModel.shared
    
    @State var tasks: [UserTask] = [
//        UserTask(taskName: "Go Gym and do some exercises", description: "Workout session", startTime: "5:00PM", endTime: "6:30AM", date: Date(), priority: .high, alert: .oneHour, category: .sports, isCompleted: true),
//        UserTask(taskName: "I want to study OOPs in C++", description: "Study Session", startTime: "6:00PM", endTime: "7:30PM", date: Date(), priority: .medium, alert: .oneHour, category: .study),
//        UserTask(taskName: "Attend a meeting", description: "Work discussion", startTime: "10:00AM", endTime: "11:30AM", date: getMarch17Date(), priority: .high, alert: .oneHour, category: .work)
    ]
    
    var body: some View {
        ScrollView (showsIndicators: false){
            // Header Section
            headerView
            
            // Weekly Dates Picker
            weekView
            
            // Task List
            taskList
            
            Spacer()
        }
        .padding()
        .onAppear {
            guard let x = loggedUser else { return }
            tasks = taskModel.getAllTasks(for: x.userId)
            loggedUser = taskModel.getUser(by: x.userId)
        }
    }
    // MARK: - Header View
    private var headerView: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome, \(loggedUser?.name ?? "User")")
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
//                DispatchQueue.main.asyncAfter(deadline: .now()) { // Add a slight delay
                    if let firstDate = Date().fullWeekDates().first(where: { $0.isSameDay(as: selectedDate) }) {
                        withAnimation{
                            proxy.scrollTo(firstDate, anchor: .center)
                        }
                    }
//                }
                
                
            }

        }
    }


    // MARK: - Task List
    private var taskList: some View {
        VStack(alignment: .center) {
            Text("My Tasks")
                .font(.title.bold())
                .padding(.top)
            
            segemntedTasks
        }
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
                                        .foregroundColor(.purple)
                                    
                                    Spacer()
                                    
                                    Text("\(categoryTasks.count)")
                                        .padding(8)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                    
                                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.purple)
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
                                        .foregroundColor(.purple)
                                    
                                    Spacer()
                                    
                                    Text("\(priorityTasks.count)")
                                        .padding(8)
                                        .background(Color.purple)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                    
                                    Image(systemName: expandedPriorities.contains(priority) ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.purple)
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
                let overdueTasks = taskModel.fetchOverdueTasks(for: user.userId)
                
                if overdueTasks.isEmpty {
                    Text("No overdue tasks 🎉")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(overdueTasks) { task in
                        NavigationLink(destination: TaskDetailView(task: task, loggedUser: loggedUser)) {
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
