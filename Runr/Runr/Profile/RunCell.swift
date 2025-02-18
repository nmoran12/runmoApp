//
//  RunCell.swift
//  Runr
//
//  Created by Noah Moran on 15/1/2025.
//

import SwiftUI
import MapKit

struct RunCell: View {
    var run: RunData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header showing run date
            HStack {
                Image(systemName: "figure.run.circle")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    Text("Run")
                        .fontWeight(.bold)
                    Text(run.date, formatter: dateFormatter)
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
                Spacer()
            }
            .padding(.horizontal)

            // Running data
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distance:")
                        .fontWeight(.semibold)
                    Text(String(format: "%.2f km", run.distance / 1000))
                }
                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Time:")
                        .fontWeight(.semibold)
                    let timeMinutes = Int(run.elapsedTime) / 60
                    let timeSeconds = Int(run.elapsedTime) % 60
                    Text(String(format: "%d min %02d sec", timeMinutes, timeSeconds))
                }
                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pace:")
                        .fontWeight(.semibold)
                    let paceInSecondsPerKm = run.elapsedTime / (run.distance / 1000)
                    let paceMinutes = Int(paceInSecondsPerKm) / 60
                    let paceSeconds = Int(paceInSecondsPerKm) % 60
                    Text(String(format: "%d:%02d / km", paceMinutes, paceSeconds))
                }
            }
            .font(.footnote)
            .padding(.horizontal)

            // Route map (if coordinates are available)
            if !run.routeCoordinates.isEmpty {
                RouteMapView(routeCoordinates: run.routeCoordinates)
                    .frame(height: 200)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Divider()
        }
        .padding(.vertical)
    }

    // Date formatter for displaying the run date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

#Preview {
    RunCell(run: RunData(date: Date(), distance: 5000, elapsedTime: 1800, routeCoordinates: []))
}

