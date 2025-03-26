//
//  ProfileView.swift
//  SwiftUISynker
//
//  Created by Deepankar Garg on 25/03/25.
//

import SwiftUI

struct ProfileView: View {
    @State var loggedUser: User
    @State private var isEditing = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @Environment(\.presentationMode) var presentationMode // To navigate back

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding(.top, 20)

                // User Info Card
                VStack(alignment: .leading, spacing: 10) {
                    ProfileRow(title: "Name", value: loggedUser.name)
                    ProfileRow(title: "Email", value: loggedUser.email)
                    ProfileRow(title: "Phone", value: loggedUser.phone)
                    ProfileRow(title: "Notifications", value: loggedUser.settings.notificationsEnabled ? "Enabled" : "Disabled")
                    ProfileRow(title: "Usage Type", value: loggedUser.settings.usage.rawValue)
                    ProfileRow(title: "Bedtime", value: loggedUser.settings.bedtime)
                    ProfileRow(title: "Wake Up Time", value: loggedUser.settings.wakeUpTime)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 15).fill(Color(.systemGray6)))
                .padding(.horizontal)

                // Buttons
                VStack(spacing: 15) {
                    Button(action: { showLogoutAlert.toggle() }) {
                        Text("Logout")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: { showDeleteAlert.toggle() }) {
                        Text("Delete Account")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing.toggle()
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditProfileView(user: $loggedUser)
        }
        .alert("Confirm Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) { logout() }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Confirm Account Deletion", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteAccount() }
        } message: {
            Text("This action cannot be undone. Are you sure you want to delete your account?")
        }
        .onAppear {
            let taskModel = TaskDataModel.shared
            loggedUser = taskModel.getUser(by: loggedUser.userId) ?? loggedUser
//            print(taskModel.getUser(by: x.userId) ?? "good")
        }
    }

    // MARK: - Logout Function
    private func logout() {
        isLoggedIn = false
    }

    // MARK: - Delete Account Function
    private func deleteAccount() {
        let taskModel = TaskDataModel.shared
//        print(taskModel.getUser(by: loggedUser.userId) ?? "good")
        let checkDelete = taskModel.deleteUser(loggedUser.userId)
        if checkDelete{
            isLoggedIn = false
        } else {
            print("Error deleting account!")
        }
    }
}

// MARK: - Profile Row Component
struct ProfileRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.bold)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}
