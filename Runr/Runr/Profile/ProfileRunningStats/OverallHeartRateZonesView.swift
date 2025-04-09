//
//  OverallHeartRateZonesView.swift
//  Runr
//
//  Created by Noah Moran on 9/4/2025.
//

import SwiftUI

/// OverallHeartRateZonesView aggregates heart rate zones from all runs and displays them as a card.
struct OverallHeartRateZonesView: View {
    /// Array of runs to aggregate data from.
    let runs: [RunData]
    
    /// A local definition for heart rate zones.
    struct HeartRateZone: Identifiable {
        var id: String { name }
        let name: String
        let lowerBound: Double
        let upperBound: Double
        var duration: TimeInterval  // total duration in seconds
        
        /// Returns a formatted string for the duration (minutes:seconds).
        func durationString() -> String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// For demonstration, we simulate each run’s heart rate zone data.
    /// Replace this with your actual run.zone data if available.
    private func simulatedZones(for run: RunData) -> [HeartRateZone] {
        return [
            HeartRateZone(name: "Zone 1", lowerBound: 0.50 * (220 - 30), upperBound: 0.60 * (220 - 30), duration: Double.random(in: 100...200)),
            HeartRateZone(name: "Zone 2", lowerBound: 0.60 * (220 - 30), upperBound: 0.70 * (220 - 30), duration: Double.random(in: 50...150)),
            HeartRateZone(name: "Zone 3", lowerBound: 0.70 * (220 - 30), upperBound: 0.80 * (220 - 30), duration: Double.random(in: 30...100)),
            HeartRateZone(name: "Zone 4", lowerBound: 0.80 * (220 - 30), upperBound: 0.90 * (220 - 30), duration: Double.random(in: 10...50)),
            HeartRateZone(name: "Zone 5", lowerBound: 0.90 * (220 - 30), upperBound: 1.00 * (220 - 30) + 1, duration: Double.random(in: 0...30))
        ]
    }
    
    /// Aggregates heart rate zones from the given runs by summing the duration for zones with the same name.
    private func aggregateZones() -> [HeartRateZone] {
        var zonesDict: [String: HeartRateZone] = [:]
        for run in runs {
            let zones = simulatedZones(for: run)  // Replace with your actual data if available.
            for zone in zones {
                if let existing = zonesDict[zone.name] {
                    let updated = HeartRateZone(
                        name: zone.name,
                        lowerBound: zone.lowerBound,
                        upperBound: zone.upperBound,
                        duration: existing.duration + zone.duration
                    )
                    zonesDict[zone.name] = updated
                } else {
                    zonesDict[zone.name] = zone
                }
            }
        }
        return zonesDict.values.sorted { $0.name < $1.name }
    }
    
    /// Determines a color for a given heart rate zone.
    private func colorForZone(_ zone: HeartRateZone) -> Color {
        switch zone.name {
        case "Zone 1": return Color.blue
        case "Zone 2": return Color.green
        case "Zone 3": return Color.yellow
        case "Zone 4": return Color.orange
        case "Zone 5": return Color.red
        default:       return Color.gray
        }
    }
    
    var body: some View {
        let zones = aggregateZones()
        let totalDuration = zones.reduce(0) { $0 + $1.duration }
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Heart Rate Zones")
                .font(.headline)
            
            ForEach(zones) { zone in
                VStack(alignment: .leading, spacing: 4) {
                    // Row showing the BPM, time, and percentage.
                    HStack {
                        Text("\(Int(zone.lowerBound))-\(Int(zone.upperBound)) BPM")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(zone.durationString())
                            .font(.caption)
                        
                        let percent = totalDuration > 0 ? (zone.duration / totalDuration) * 100 : 0
                        Text(String(format: "%.0f%%", percent))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    // A horizontal bar showing the relative duration.
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForZone(zone))
                                .frame(width: geometry.size.width * CGFloat(totalDuration > 0 ? zone.duration / totalDuration : 0), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(Color.white)  // White background for the card.
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
