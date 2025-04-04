//
//  CardViewInsideView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct CardViewInsideView: View {
    let effort: BestEffortsViewModel.BestEffort
    
    var body: some View {
        HStack(spacing: 12) {
            // Use BestEffortsBadgesView to display the circle icon.
            BestEffortsBadgesView(efforts: [effort])
                .frame(width: 40, height: 40)
            
            // Distance & date – now using the run date from the model.
            VStack(alignment: .leading, spacing: 2) {
                Text(effort.distance)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                if let runDate = effort.date {
                    // Format the date as desired; here we use a short date style.
                    Text(runDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Time & pace on the right.
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedTime(effort.time))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                // Placeholder pace. Replace with actual pace if available.
                Text("5:15 /km")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formattedTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

struct CardViewInsideView_Previews: PreviewProvider {
    static var previews: some View {
        CardViewInsideView(effort: BestEffortsViewModel.BestEffort(distance: "5K", time: 1500, date: Date()))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

