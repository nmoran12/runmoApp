//
//  GoalCard.swift
//  Runr
//
//  Created by Noah Moran on 2/4/2025.
//

import SwiftUI

// Generic GoalCard that accepts any content.
struct GoalCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Renamed the specific instantiation to avoid conflict.
struct AveragePaceGoalCard: View {
    @State private var averagePaceImprovement: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GoalCard(title: "Average Pace Improvement", icon: "arrow.down") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Improvement (seconds/km)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("0", text: $averagePaceImprovement)
                        .keyboardType(.decimalPad)
                        .font(.title3.bold())
                    
                    Text("sec/km")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                ProgressBar(value: 0.4)
            }
        }
    }
}

// Simple progress bar view used by the cards.
struct ProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 8)
                    .opacity(0.1)
                    .foregroundColor(Color.blue)
                    .cornerRadius(4)
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: 8)
                    .foregroundColor(Color.blue)
                    .cornerRadius(4)
            }
        }
        .frame(height: 8)
    }
}

struct GoalCard_Previews: PreviewProvider {
    static var previews: some View {
        GoalCard(title: "Test Goal", icon: "star.fill") {
            Text("Example Content")
                .font(.subheadline)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

