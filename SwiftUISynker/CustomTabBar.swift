import SwiftUI

struct CustomTabBar: View {
    @State private var selectedTab = 0
    @State private var isCreateTaskPresented = false // State to show CreateTaskView
    @State private var isCreateTimeCapsulePresented = false // State to show CreateTaskView
    @State private var isUpdated = false // State to show CreateTaskView
    @State private var isUpdatedTimeCapsule = false // State to show CreateTaskView
    @State var loggedUser: User?  // User is now passed
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationView {
                    HomeView(loggedUser: loggedUser)
                }
                    .id(isUpdated)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)

                NavigationView {
                    TimeCapsuleScreen(loggedUser: loggedUser)
                }
                    .id(isUpdatedTimeCapsule)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Time Capsule")
                    }
                    .tag(1)

                NavigationView {
                    AwardsView()
                }
                    .tabItem {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Awards")
                    }
                    .tag(2)

                NavigationView {
                    ProfileView(loggedUser: loggedUser ?? User(
                        name: "Guest",
                        email: "guest@example.com",
                        password: "",
                        phone: "N/A",
                        settings: Settings(usage: .personal, bedtime: "10:00 PM", wakeUpTime: "6:00 AM", notificationsEnabled: true)
                    ))
                }
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(3)
            }

            // Floating Add Button
            VStack {
                Spacer()
                if selectedTab == 0 {
                    AddButton {
                        isCreateTaskPresented.toggle()
                    }
                }
                if selectedTab == 1 {
                    AddTimeCapsuleButton {
                        isCreateTimeCapsulePresented.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $isCreateTaskPresented, onDismiss: {
            isUpdated = false
        }) {
            CreateTaskView(isUpdated: $isUpdated, loggedUser: loggedUser)
        }
        .sheet(isPresented: $isCreateTimeCapsulePresented, onDismiss: {
            isUpdatedTimeCapsule = false
        }) {
            CreateTimeCapsuleView(isUpdated: $isUpdatedTimeCapsule,loggedUser: loggedUser)
        }
    }
}

// MARK: - Floating Add Button
struct AddButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 65, height: 65)
                    .shadow(radius: 5)

                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.system(size: 30, weight: .bold))
            }
        }
        .offset(y: -30) // Move button above the tab bar
    }
}

// MARK: - Floating Add Button
struct AddTimeCapsuleButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 65, height: 65)
                    .shadow(radius: 5)

                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.system(size: 30, weight: .bold))
            }
        }
        .offset(y: -30) // Move button above the tab bar
    }
}

// MARK: - Placeholder Views for Tabs

struct AwardsView: View {
    var body: some View {
        Text("Awards Screen").font(.largeTitle)
    }
}
