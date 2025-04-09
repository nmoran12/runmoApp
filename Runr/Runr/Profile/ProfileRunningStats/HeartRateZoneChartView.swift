//
//  HeartRateZoneGraphView.swift
//  Runr
//
//  Created by Noah Moran on 9/4/2025.
//

import SwiftUI

/// HeartRateZoneChartView shows a stacked horizontal bar for each run,
/// where the x-axis represents time (run duration) and each run is a row.
/// Each bar is segmented by heart rate zones (ordered from left to right).
struct HeartRateZoneChartView: View {
    /// The runs to display. Each RunData must have a unique id and a date.
    let runs: [RunData]
    
    // MARK: - Data Structures
    
    /// Represents a heart rate zone for a given run.
    struct HeartRateZone: Identifiable {
        var id: String { name }
        let name: String
        let lowerBound: Double
        let upperBound: Double
        var duration: TimeInterval  // Duration in seconds spent in this zone.
    }
    
    /// Aggregated heart rate zone data for one run.
    struct RunZoneData: Identifiable {
        let id: String        // Run id.
        let date: Date        // Date of the run (for labeling).
        let zones: [HeartRateZone] // Zones for this run, assumed sorted in desired order.
        var totalDuration: TimeInterval {
            zones.reduce(0) { $0 + $1.duration }
        }
    }
    
    // MARK: - Data Aggregation Helpers
    
    /// Simulates heart rate zone data for a given run.
    /// Replace this function with your actual data retrieval.
    private func simulatedZones(for run: RunData) -> [HeartRateZone] {
        // For demonstration, we simulate durations in seconds.
        return [
            HeartRateZone(name: "Zone 1", lowerBound: 100, upperBound: 120, duration: Double.random(in: 100...200)),
            HeartRateZone(name: "Zone 2", lowerBound: 121, upperBound: 140, duration: Double.random(in: 50...150)),
            HeartRateZone(name: "Zone 3", lowerBound: 141, upperBound: 160, duration: Double.random(in: 30...100)),
            HeartRateZone(name: "Zone 4", lowerBound: 161, upperBound: 180, duration: Double.random(in: 10...50)),
            HeartRateZone(name: "Zone 5", lowerBound: 181, upperBound: 200, duration: Double.random(in: 0...30))
        ]
    }
    
    /// Converts each RunData into RunZoneData by aggregating heart rate zones.
    /// In a real app, if you already store heart rate zones with your RunData, use that instead.
    var runZoneDataArray: [RunZoneData] {
        runs.map { run in
            // Get zones and sort them in the desired order.
            // Here we assume lower zones come first.
            let zones = simulatedZones(for: run).sorted { $0.name < $1.name }
            return RunZoneData(id: run.id, date: run.date, zones: zones)
        }
        // Optionally sort by date (most recent first).
        .sorted { $0.date > $1.date }
    }
    
    /// Returns a consistent color for a given heart rate zone.
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
    
    // MARK: - Body
    
    var body: some View {
        // Using a vertical ScrollView so that many runs can be displayed without white space between rows.
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                ForEach(runZoneDataArray) { runData in
                    HStack(spacing: 0) {
                        // Optional: Run label column.
                        Text(shortDateFormatter.string(from: runData.date))
                            .font(.caption)
                            .frame(width: 50)
                            .foregroundColor(.secondary)
                        
                        // The stacked bar for this run.
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                ForEach(runData.zones) { zone in
                                    let proportion = runData.totalDuration > 0 ? zone.duration / runData.totalDuration : 0
                                    Rectangle()
                                        .fill(colorForZone(zone).opacity(0.8))
                                        .frame(width: geometry.size.width * CGFloat(proportion))
                                }
                            }
                        }
                        .frame(height: 20)
                    }
                    // No spacing between rows.
                }
            }
            .padding(.vertical, 4) // Minimal vertical padding for overall content.
        }
        .padding(8)
        .background(Color.white)  // White background for the card.
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    /// A DateFormatter for a short date label.
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}
