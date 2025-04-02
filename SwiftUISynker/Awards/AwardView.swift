//
//  AwardView.swift
//  SwiftUISynker
//
//  Created by Deepankar Garg on 29/03/25.
//
import SwiftUI

struct AwardsView: View {
    @State var loggedUser: User?

    @State private var allAwards: [Award] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text("Awards")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)

            // Streak Stats
            HStack {
                StreakCard(title: "Current streak", value: "\(loggedUser?.totalStreak ?? 0) Days", icon: "flame.fill")
                StreakCard(title: "Max streak", value: "\(loggedUser?.maxStreak ?? 0) Days", icon: "flame.fill")
            }
            .padding(.horizontal)

            // Show Earned Awards Only
            SectionHeader(title: "Earned Awards")

            if let earnedAwards = loggedUser?.awardsEarned, !earnedAwards.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(earnedAwards) { earned in
                            if let matchingAward = allAwards.first(where: { $0.id == earned.awardId }) {
                                AwardCard(award: matchingAward, dateEarned: earned.dateEarned)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("No awards earned yet.")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .onAppear(){
            let taskModel = TaskDataModel.shared
            allAwards = taskModel.getAllAwards()
            if let x = loggedUser {
                loggedUser = taskModel.getUser(by: x.userId)
            }
        }
    }
}

// Section Header Component
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
    }
}

// Streak Card Component
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

// Award Card (Earned Awards)
struct AwardCard: View {
    let award: Award
    let dateEarned: Date

    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.yellow)

            Text(award.awardName)
                .font(.subheadline)
                .fontWeight(.bold)

            Text(formatDate(dateEarned))
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

//#Preview {
//    AwardsView()
//}
