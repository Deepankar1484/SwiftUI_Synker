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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Add a slight delay
                    if let firstDate = Date().fullWeekDates().first(where: { $0.isSameDay(as: selectedDate) }) {
                        withAnimation{
                            proxy.scrollTo(firstDate, anchor: .center)
                        }
                    }
                }
                
                
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
                Text("Overdue tasks will be listed here.")
                    .foregroundColor(.gray)
                    .padding()
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
            ForEach(Category.allCases, id: \.self) { category in
                let categoryTasks = tasks.filter { $0.category == category && $0.date.isSameDay(as: selectedDate) }
                
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
                                    .foregroundColor(.purple) // Category Name in Purple
                                
                                Spacer()
                                
                                Text("\(categoryTasks.count)")
                                    .padding(8)
                                    .background(Color.black) // Background Purple
                                    .foregroundColor(.white) // White Text
                                    .clipShape(Circle())
                                
                                // Custom Expand Arrow (Inside the Box)
                                Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.purple) // Purple Arrow
                                    .font(.system(size: 16, weight: .bold))
                                    .rotationEffect(expandedCategories.contains(category) ? .degrees(180) : .degrees(0)) // Smooth Rotate
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                        }
                        
                        // Expandable Content with Animation
                        if expandedCategories.contains(category) {
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(categoryTasks) { task in
                                    NavigationLink(destination: TaskDetailView(task: task, loggedUser: loggedUser)) {
                                        TaskRow(task: task)
                                            .padding(.vertical, 3)
                                            .transition(.move(edge: .top).combined(with: .opacity)) // Smooth transition
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.leading, 10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }


    // MARK: - Priority View
    private var priorityView: some View {
        VStack(spacing: 10) {
            ForEach(Priority.allCases, id: \.self) { priority in
                let priorityTasks = tasks.filter { $0.priority == priority && $0.date.isSameDay(as: selectedDate) }
                
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
                                    .foregroundColor(.purple) // Priority Name in Purple
                                
                                Spacer()
                                
                                Text("\(priorityTasks.count)")
                                    .padding(8)
                                    .background(Color.purple) // Background Purple
                                    .foregroundColor(.white) // White Text
                                    .clipShape(Circle())
                                
                                // Custom Expand Arrow (Inside the Box)
                                Image(systemName: expandedPriorities.contains(priority) ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.purple) // Purple Arrow
                                    .font(.system(size: 16, weight: .bold))
                                    .rotationEffect(expandedPriorities.contains(priority) ? .degrees(180) : .degrees(0)) // Smooth Rotate
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                        }
                        
                        // Expandable Content with Animation
                        if expandedPriorities.contains(priority) {
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(priorityTasks) { task in
                                    NavigationLink(destination: TaskDetailView(task: task, loggedUser: loggedUser)) {
                                        TaskRow(task: task)
                                            .padding(.vertical, 3)
                                            .transition(.move(edge: .top).combined(with: .opacity)) // Smooth transition
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.leading, 10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }


    // MARK: - Category Tile
//    private func categoryTile(title: String, count: Int) -> some View {
//        HStack {
//            Text(title)
//                .font(.title3.bold())
//            Spacer()
//            Text("\(count)")
//                .padding(8)
//                .background(Color.black)
//                .foregroundColor(.white)
//                .clipShape(Circle())
//        }
//        .padding()
//        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
//        .padding(.horizontal)
//    }
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
