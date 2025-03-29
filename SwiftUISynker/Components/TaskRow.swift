//
//  TaskRow.swift
//  SynkrSwiftUI
//
//  Created by Deepankar Garg on 16/03/25.
//
import SwiftUI

struct TaskRow: View {
    let task: UserTask

    var body: some View {
        HStack {
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(task.priority.tintColor))
            } else {
                Image(systemName: "flag.circle")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(task.priority.tintColor))
            }

            HStack(spacing: 14) {
                if task.category == .others {
                    Image(task.category.taskImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: task.category.taskImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.category.rawValue.capitalized)
                        .font(.subheadline)

                    Text(task.taskName)
                        .font(.headline)
                        .lineLimit(2)
                        .truncationMode(.tail)

                    Text("\(task.startTime) - \(task.endTime)")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .padding()
            .background(
                Color(task.category.customCategory.categoryColor)
                    .cornerRadius(10)
            )
            .overlay(
                task.isCompleted ?
                Color.white.opacity(0.5) : Color.clear
            )
            .overlay(
                shouldShowBorder ? RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.6), lineWidth: 3) : nil
            )
        }
    }

    // Check if the current time is between the task's start and end time
    private var shouldShowBorder: Bool {
        guard !task.isCompleted,
              let startTime = Date.fromTimeString(task.startTime),
              let endTime = Date.fromTimeString(task.endTime) else {
            return false
        }

        let x = Date().timeString()
        if let currentTime = Date.fromTimeString(x){
            return currentTime >= startTime && currentTime <= endTime
        } else{ return false}
    }
}
