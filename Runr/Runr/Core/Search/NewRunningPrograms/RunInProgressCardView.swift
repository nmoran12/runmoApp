//
//  RunInProgressCardView.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import SwiftUI

struct RunningProgramBarView: View {
    var targetDistance: Double
    var currentDistance: Double
    
    private var remainingDistance: Double {
        max(targetDistance - currentDistance, 0)
    }
    
    var body: some View {
        HStack {
            // Circle with running icon
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "figure.run")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                )
                .padding(.leading, 5)
            
            // Target distance text
            VStack(alignment: .leading, spacing: 1) {
                Text("Today's Target")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.2f km", targetDistance))
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .padding(.leading, 4)
                
                Text(String(format: "Remaining: %.2f km", remainingDistance))
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .padding(.leading, 4)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6).opacity(0.6))
        .cornerRadius(8)
        .padding(.horizontal, 10)
        .padding(.top, 15)
    }
}

struct RunningProgramBarView_Previews: PreviewProvider {
    static var previews: some View {
        RunningProgramBarView(targetDistance: 5.0, currentDistance: 0.0)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
