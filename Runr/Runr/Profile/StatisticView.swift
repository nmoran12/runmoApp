//
//  StatisticView.swift
//  Runr
//
//  Created by Noah Moran on 15/1/2025.
//

import SwiftUI

struct StatisticView: View {
    let value: String
    let label: String
    let unit: String

    var body: some View {
        VStack {
            Text("\(value)\(unit)")
                .font(.title)
                .fontWeight(.bold)
                .minimumScaleFactor(0.5) // Allows text to scale down to 50% of its original size
                .lineLimit(1)            // Ensures the text stays on one line
                .frame(maxWidth: .infinity) // Makes sure it occupies available space equally
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}



#Preview {
    StatisticView(value: "100.0", label: "Distance", unit: "km")
}

extension StatisticView {
    static func formatTime(from hours: Double) -> String {
        let totalSeconds = Int(hours * 3600) // Convert hours to total seconds
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours) hrs \(minutes) mins"
        } else if minutes > 0 {
            return "\(minutes) mins \(seconds) secs"
        } else {
            return "\(seconds) secs"
        }
    }


    static func formatPace(from totalTime: Double, and totalDistance: Double) -> String {
        guard totalDistance > 0 else { return "0:00 min/km" }
        
        // Convert totalTime from hours to minutes
        let timeInMinutes = totalTime * 60
        
        // Calculate pace as minutes per kilometer
        let pace = timeInMinutes / totalDistance
        
        // Extract whole minutes and remaining seconds
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        
        return String(format: "%d:%02d min/km", minutes, seconds)
    }


}
