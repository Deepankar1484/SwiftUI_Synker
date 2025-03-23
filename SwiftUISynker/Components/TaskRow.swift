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
        HStack{
            Image(systemName: "flag.circle")
                .font(.system(size: 28, weight: .bold)) // Bigger & Bolder
                .foregroundColor(Color(task.priority.tintColor))

            HStack(spacing: 16) {
                if(task.category == .others){
                    Image(task.category.taskImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40) // Bigger icon
                        .foregroundColor(.white)
                        .padding(.leading)
                    
                } else{
                    Image(systemName: task.category.taskImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40) // Bigger icon
                        .foregroundColor(.white)
                        .padding(.leading)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.category.rawValue.capitalized) // Category Name
                        .font(.subheadline)
                    
                    Text(task.taskName) // Task Name
                        .font(.headline)
                        .lineLimit(2)
                        .truncationMode(.tail)
                    
                    Text("\(task.startTime) - \(task.endTime)") // Time
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                Text(">")
            }
            .padding()
            .background(
                Color(task.category.customCategory.categoryColor)
                    .cornerRadius(10)
                    .opacity(1.0) // Keep full opacity
            )
            .overlay(
                task.isCompleted ?
                Color.white.opacity(0.5) : Color.clear // Add an overlay for completed tasks
            )
        }

    }
}

//#Preview {
//    TaskRow()
//}
