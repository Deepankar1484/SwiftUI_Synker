//
//  AwardView.swift
//  SwiftUISynker
//
//  Created by Deepankar Garg on 29/03/25.
//

import SwiftUI

struct AwardsView: View {
    @State private var currentStreak: Int = 0
    @State private var maxStreak: Int = 0
    
    let allAwards: [Award] = [
        Award(awardName: "First Task Completed", description: "Completed your first task"),
        Award(awardName: "5-Day Streak", description: "Completed tasks for 5 consecutive days"),
        Award(awardName: "Time Master", description: "Completed 10 time capsules")
    ]
    
    let earnedAwards: [AwardsEarned] = [
        AwardsEarned(awardId: UUID(), dateEarned: Date())
    ]
    
    var lockedAwards: [Award] {
        allAwards.filter { award in
            !earnedAwards.contains(where: { $0.awardId == award.id })
        }
    }
    
    var body: some View {
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
            
            SectionHeader(title: "Earned Awards")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(earnedAwards, id: \ .id) { award in
                        if let matchingAward = allAwards.first(where: { $0.id == award.awardId }) {
                            AwardCard(award: matchingAward, dateEarned: award.dateEarned)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            SectionHeader(title: "Locked Awards")
            
            List {
                ForEach(lockedAwards, id: \ .id) { award in
                    LockedAwardRow(award: award)
                }
            }
            .listStyle(PlainListStyle())
        }
        .onAppear {
            updateStreaks()
        }
    }
    
    private func updateStreaks() {
        // Add logic to calculate streaks dynamically
        currentStreak = 6
        maxStreak = 96
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
            Button("See All") {}
                .foregroundColor(.blue)
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

// Locked Award Row
struct LockedAwardRow: View {
    let award: Award
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
                
            VStack(alignment: .leading) {
                Text(award.awardName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(award.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    AwardsView()
}
