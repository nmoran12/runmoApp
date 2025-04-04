//
//  ElevationView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI
import Charts
import CoreLocation

func computeElevation(from locations: [TimedLocation]) -> (gain: Double, loss: Double) {
    guard locations.count > 1 else { return (0, 0) }
    
    var totalGain: Double = 0
    var totalLoss: Double = 0
    
    for i in 1..<locations.count {
        let elevationDiff = locations[i].altitude - locations[i-1].altitude
        if elevationDiff > 0 {
            totalGain += elevationDiff
        } else {
            totalLoss += abs(elevationDiff)
        }
    }
    
    return (gain: totalGain, loss: totalLoss)
}

struct ElevationDataPoint: Identifiable {
    let id = UUID()
    let distance: Double  // cumulative distance (in metres)
    let altitude: Double  // relative altitude (in metres)
}

struct ElevationView: View {
    let locations: [TimedLocation]
    
    // Compute cumulative distance and relative altitude.
    // The relative altitude is computed by subtracting the minimum altitude from every value.
    var elevationData: [ElevationDataPoint] {
        guard !locations.isEmpty else { return [] }
        let minAltitude = locations.map { $0.altitude }.min() ?? 0
        var points: [ElevationDataPoint] = []
        var totalDistance: Double = 0
        for (index, loc) in locations.enumerated() {
            let relativeAltitude = loc.altitude - minAltitude
            if index == 0 {
                points.append(ElevationDataPoint(distance: 0, altitude: relativeAltitude))
            } else {
                let prev = locations[index - 1]
                let d = CLLocation(latitude: prev.coordinate.latitude,
                                   longitude: prev.coordinate.longitude)
                    .distance(from: CLLocation(latitude: loc.coordinate.latitude,
                                               longitude: loc.coordinate.longitude))
                totalDistance += d
                points.append(ElevationDataPoint(distance: totalDistance, altitude: relativeAltitude))
            }
        }
        return points
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Elevation")
                .font(.headline)
                .padding(.leading)
            
            Chart {
                // Fill area under the elevation line with light blue.
                ForEach(elevationData) { point in
                    AreaMark(
                        x: .value("Distance", point.distance),
                        y: .value("Elevation", point.altitude)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(Color.blue.opacity(0.3))
                }
                // Draw the elevation line in blue.
                ForEach(elevationData) { point in
                    LineMark(
                        x: .value("Distance", point.distance),
                        y: .value("Elevation", point.altitude)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(.blue)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartXAxisLabel("Distance", alignment: .center)
            
            // Set y-axis tick marks to stride by 5 metres.
            .chartYAxis {
                AxisMarks(values: .stride(by: 5))
            }
            .chartYAxisLabel("metres", position: .automatic)
            .frame(height: 200)
        }
    }
}

struct ElevationView_Previews: PreviewProvider {
    static var sampleLocations: [TimedLocation] = [
        TimedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            timestamp: Date(),
            altitude: 150
        ),
        TimedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            timestamp: Date().addingTimeInterval(10),
            altitude: 155
        ),
        TimedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4196),
            timestamp: Date().addingTimeInterval(20),
            altitude: 152
        ),
        TimedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4197),
            timestamp: Date().addingTimeInterval(30),
            altitude: 158
        )
    ]
    
    static var previews: some View {
        ElevationView(locations: sampleLocations)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
