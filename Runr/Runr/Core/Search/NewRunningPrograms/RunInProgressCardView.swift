//
//  RunInProgressCardView.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import SwiftUI

struct RunningProgramBarView: View {
    var targetDistance: Double    // in kilometres
    var currentDistance: Double   // in metres
    var dailyRunType: String      // new property

    // Calculate remaining distance after converting currentDistance to kilometers.
    private var remainingDistance: Double {
        let currentKm = currentDistance / 1000.0
        return max(targetDistance - currentKm, 0)
    }
    
    var body: some View {
        HStack {
            // Circle with running icon remains unchanged.
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "figure.run")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                )
                .padding(.leading, 5)
            
            // Instead of the previous VStack, we now display:
            // "Today's Run" on top, then the dailyRunType, then the remaining distance.
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Run")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(dailyRunType)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(String(format: "%.2f km to go", remainingDistance))
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.leading, 4)
            
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
        // Example: target is 7.5 km and currentDistance is 3000 metres (3 km)
        RunningProgramBarView(targetDistance: 7.5, currentDistance: 3000, dailyRunType: "Long Run")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
