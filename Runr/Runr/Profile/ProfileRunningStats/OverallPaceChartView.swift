//
//  OverallPaceChartView.swift
//  Runr
//
//  Created by Noah Moran on 9/4/2025.
//

import SwiftUI
import Charts    // Requires iOS 16 or higher
import CoreLocation

/// This view aggregates pace data from multiple runs and displays each run’s pace over distance as a line in a chart.
struct OverallPaceChartView: View {
    /// The runs to include – you might pass in filtered runs from ProfileStatsView.
    let runs: [RunData]
    
    /// Options for distance thresholds.
    private let distanceOptions: [(title: String, threshold: Double?)] = [
        ("All", nil),
        ("5 km", 5.0),
        ("10 km", 10.0),
        ("Marathon", 42.195)
    ]
    
    /// Selected threshold value. If nil then show all available data.
    @State private var selectedDistanceThreshold: Double? = nil
    
    /// A state variable for controlling the Y-axis scale via a pinch gesture.
    /// When chartScale == 1.0, the domain is ±1 min/km around the overall average.
    @State private var chartScale: CGFloat = 1.0
    
    /// A simple wrapper that holds a run’s id and its pace data.
    struct RunPaceData: Identifiable {
        let id: String         // Unique identifier for the run
        let paceData: [PaceData]
    }
    
    /// Create an array of RunPaceData from the provided runs.
    /// For each run, we simulate timed locations using its routeCoordinates and compute pace data.
    var runPaceDatas: [RunPaceData] {
        runs.enumerated().compactMap { (index, run) in
            guard !run.routeCoordinates.isEmpty else { return nil }
            let totalPoints = run.routeCoordinates.count
            // Create simulated timed locations along the route.
            let timedLocations = run.routeCoordinates.enumerated().map { (i, coordinate) in
                // Evenly distribute timestamps over the run's elapsed time.
                let t = Double(i) / Double(max(totalPoints - 1, 1))
                let approxTime = run.date.addingTimeInterval(t * run.elapsedTime)
                return TimedLocation(coordinate: coordinate, timestamp: approxTime, altitude: 0)
            }
            // Compute pace data using your helper.
            let paceData = createPaceData(from: timedLocations)
            return RunPaceData(id: run.id, paceData: paceData)
        }
    }
    
    /// Helper: Given an array of PaceData and a threshold, return a new array that is clipped to the threshold.
    /// If the run extends beyond the threshold, we interpolate a new data point at exactly that distance.
    func clippedPaceData(from paceData: [PaceData], threshold: Double) -> [PaceData] {
        // If the run doesn't reach the threshold, return an empty array.
        guard let last = paceData.last, last.distanceKm >= threshold else {
            return []
        }
        
        // Filter out points up to the threshold.
        let clipped = paceData.filter { $0.distanceKm <= threshold }
        
        // If the last clipped point is exactly at the threshold, return.
        if let lastClipped = clipped.last, abs(lastClipped.distanceKm - threshold) < 0.001 {
            return clipped
        }
        
        // Otherwise, interpolate a point exactly at the threshold.
        if let before = paceData.last(where: { $0.distanceKm <= threshold }),
           let after = paceData.first(where: { $0.distanceKm > threshold }) {
            let fraction = (threshold - before.distanceKm) / (after.distanceKm - before.distanceKm)
            let interpolatedPace = before.paceMinPerKm + fraction * (after.paceMinPerKm - before.paceMinPerKm)
            let interpolatedPoint = PaceData(distanceKm: threshold, paceMinPerKm: interpolatedPace)
            return clipped + [interpolatedPoint]
        }
        return clipped
    }
    
    /// Filter each run’s pace data based on the selected distance threshold.
    /// When a threshold is selected, if a run doesn't reach that threshold it is excluded.
    /// Otherwise, the run’s pace data is clipped to that threshold.
    var filteredRunPaceDatas: [RunPaceData] {
        if let threshold = selectedDistanceThreshold {
            return runPaceDatas.compactMap { runData in
                guard let last = runData.paceData.last, last.distanceKm >= threshold else {
                    return nil
                }
                let clippedData = clippedPaceData(from: runData.paceData, threshold: threshold)
                return RunPaceData(id: runData.id, paceData: clippedData)
            }
        } else {
            return runPaceDatas
        }
    }
    
    /// Compute the overall average pace (min/km) from all displayed pace data.
    var overallAveragePace: Double {
        let allPaces = filteredRunPaceDatas.flatMap { $0.paceData.map { $0.paceMinPerKm } }
        return allPaces.isEmpty ? 0 : allPaces.reduce(0, +) / Double(allPaces.count)
    }
    
    /// Compute the Y domain for the chart.
    var yDomain: ClosedRange<Double> {
        let delta = 1.0 * Double(chartScale)
        return overallAveragePace - delta ... overallAveragePace + delta
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Overall Pace Over Distance")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Picker for distance threshold.
            Picker("Distance Threshold", selection: $selectedDistanceThreshold) {
                ForEach(distanceOptions, id: \.title) { option in
                    Text(option.title).tag(option.threshold)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 8)
            
            // Chart container styled like a card.
            VStack {
                // The Chart wrapped with a MagnificationGesture.
                Chart {
                    ForEach(filteredRunPaceDatas) { runData in
                        ForEach(runData.paceData) { dataPoint in
                            LineMark(
                                x: .value("Distance (km)", dataPoint.distanceKm),
                                y: .value("Pace (min/km)", dataPoint.paceMinPerKm)
                            )
                            .foregroundStyle(Color.blue.opacity(0.5))
                        }
                    }
                }
                .chartLegend(.hidden)
                .chartXAxisLabel("Distance (km)")
                .chartYAxisLabel("Pace (min/km)")
                .chartYScale(domain: yDomain)
                .chartPlotStyle { plotArea in
                    plotArea.clipped()
                }
                .frame(height: 250)
                // Allow pinch-to-zoom via a MagnificationGesture.
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            chartScale = max(value, 0.5)  // Clamp to avoid extreme values.
                        }
                )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding()
    }
}
