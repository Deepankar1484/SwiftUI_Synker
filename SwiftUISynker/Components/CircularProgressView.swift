//
//  CircularProgressView.swift
//  SynkrSwiftUI
//
//  Created by Deepankar Garg on 16/03/25.
//

import SwiftUI

struct CircularProgressView: View {
    let percentage: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .opacity(0.3)
                .foregroundColor(Color.purple)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(percentage) / 100)
                .stroke(Color.purple, lineWidth: 8)
                .rotationEffect(.degrees(-90))
            
            Text("\(percentage)%")
                .font(.headline)
                .foregroundColor(.purple)
        }
        .frame(width: 80, height: 80)
    }
}

#Preview {
    CircularProgressView(percentage: 90)
}
