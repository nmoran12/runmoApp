//
//  SelectedToAddGoals.swift
//  Runr
//
//  Created by Noah Moran on 3/4/2025.
//

import SwiftUI

struct SelectedToAddGoalsView: View {
    let title: String
    let target: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Text("\(title): \(target)")
                    .font(.headline)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    SelectedToAddGoalsView(title: "Monthly Distance", target: "10km", icon: "star.fill")
}
