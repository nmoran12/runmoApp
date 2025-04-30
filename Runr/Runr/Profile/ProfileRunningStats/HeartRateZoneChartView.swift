//
//  HeartRateZoneGraphView.swift
//  Runr
//
//  Created by Noah Moran on 9/4/2025.
//

import SwiftUI

struct HeartRateZoneChartView: View {
    let runs: [RunData]

    // Configuration
    private let chartHeight: CGFloat = 200
    private let verticalPadding: CGFloat = 16
    private let horizontalPadding: CGFloat = 16

    // MARK: – Data Models

    struct HeartRateZone: Identifiable {
        var id: String { name }
        let name: String
        let duration: TimeInterval
    }

    struct RunZoneData: Identifiable {
        let id: String
        let zones: [HeartRateZone]
        var totalDuration: TimeInterval { zones.reduce(0) { $0 + $1.duration } }
    }

    // MARK: – Build your data

    private func simulatedZones(for run: RunData) -> [HeartRateZone] {
        [
            .init(name: "Zone 1", duration: Double.random(in: 100...200)),
            .init(name: "Zone 2", duration: Double.random(in: 50...150)),
            .init(name: "Zone 3", duration: Double.random(in: 30...100)),
            .init(name: "Zone 4", duration: Double.random(in: 10...50)),
            .init(name: "Zone 5", duration: Double.random(in: 0...30))
        ]
    }

    private var runZoneDataArray: [RunZoneData] {
        runs.map { run in
            let zones = simulatedZones(for: run).sorted { $0.name < $1.name }
            return RunZoneData(id: run.id, zones: zones)
        }
        .sorted { $0.id > $1.id }
    }

    private func colorForZone(_ zone: HeartRateZone) -> Color {
        switch zone.name {
        case "Zone 1": return .blue
        case "Zone 2": return .green
        case "Zone 3": return .yellow
        case "Zone 4": return .orange
        case "Zone 5": return .red
        default:         return .gray
        }
    }

    // MARK: – View

    var body: some View {
        
        GeometryReader { geo in
            let totalUsableWidth = geo.size.width - 2 * horizontalPadding
            let count = runZoneDataArray.count
            // Avoid division by zero
            let barWidth = count > 0
                ? (totalUsableWidth / CGFloat(count))
                : 0
            
            // Header
            Text("Overall Heart Rate Zones (Graph)")
                .font(.headline)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, verticalPadding)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(runZoneDataArray) { runData in
                    ZStack(alignment: .bottom) {
                        ForEach(runData.zones) { zone in
                            let pct = runData.totalDuration > 0
                                ? zone.duration / runData.totalDuration
                                : 0
                            Rectangle()
                                .fill(colorForZone(zone).opacity(0.8))
                                .frame(
                                    width: barWidth,
                                    height: chartHeight * CGFloat(pct)
                                )
                        }
                    }
                }
            }
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .frame(width: geo.size.width, height: chartHeight + verticalPadding * 2)
        }
        .frame(height: chartHeight + verticalPadding * 2)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity)
    }
}
