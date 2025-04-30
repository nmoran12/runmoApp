//
//  OverallPaceChartView.swift
//  Runr
//
//  Created by Noah Moran on 9/4/2025.
//

import SwiftUI
import Charts
import CoreLocation

// This view aggregates pace data from multiple runs and displays each run’s pace over distance as a line in a chart.
struct OverallPaceChartView: View {
    let runs: [RunData]

    // Options for distance thresholds.
    private let distanceOptions: [(title: String, threshold: Double?)] = [
        ("All", nil),
        ("5 km", 5.0),
        ("10 km", 10.0),
        ("Marathon", 42.195)
    ]

    // Selected threshold value.
    @State private var selectedDistanceThreshold: Double? = nil

    // Controls the Y-axis zoom.
    @State private var chartScale: CGFloat = 1.0

    // Wraps a run’s pace data.
    struct RunPaceData: Identifiable {
        let id: String
        let paceData: [PaceData]
    }

    // Build pace data for each run.
    var runPaceDatas: [RunPaceData] {
        runs.compactMap { run in
            guard !run.routeCoordinates.isEmpty else { return nil }
            let totalPoints = run.routeCoordinates.count
            let timed = run.routeCoordinates.enumerated().map { i, coord in
                let t = Double(i) / Double(max(totalPoints - 1, 1))
                let dateAt = run.date.addingTimeInterval(t * run.elapsedTime)
                return TimedLocation(coordinate: coord, timestamp: dateAt, altitude: 0)
            }
            let paceData = createPaceData(from: timed)
            return RunPaceData(id: run.id, paceData: paceData)
        }
    }

    // Clip or filter pace data to the selected threshold.
    var filteredRunPaceDatas: [RunPaceData] {
        guard let threshold = selectedDistanceThreshold else { return runPaceDatas }
        return runPaceDatas.compactMap { runData in
            guard let last = runData.paceData.last, last.distanceKm >= threshold else { return nil }
            return RunPaceData(id: runData.id,
                               paceData: clippedPaceData(from: runData.paceData, threshold: threshold))
        }
    }

    // Compute overall average pace.
    var overallAveragePace: Double {
        let all = filteredRunPaceDatas.flatMap { $0.paceData.map { $0.paceMinPerKm } }
        return all.isEmpty ? 0 : all.reduce(0, +) / Double(all.count)
    }

    // Y-axis domain for zooming.
    var yDomain: ClosedRange<Double> {
        let delta = 1.0 * Double(chartScale)
        return (overallAveragePace - delta)...(overallAveragePace + delta)
    }

    var body: some View {
        // Wrap everything in one styled card
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Pace Over Distance")
                .font(.headline)

            Picker("Distance Threshold", selection: $selectedDistanceThreshold) {
                ForEach(distanceOptions, id: \.title) { option in
                    Text(option.title).tag(option.threshold)
                }
            }
            .pickerStyle(.segmented)

            Chart {
                ForEach(filteredRunPaceDatas) { runData in
                    ForEach(runData.paceData) { point in
                        LineMark(
                            x: .value("Distance (km)", point.distanceKm),
                            y: .value("Pace (min/km)", point.paceMinPerKm),
                            series: .value("Run", runData.id)
                        )
                        .foregroundStyle(Color.blue.opacity(0.5))
                    }
                }
            }
            .chartXAxisLabel("Distance (km)")
            .chartYAxisLabel("Pace (min/km)")
            .chartYScale(domain: yDomain)
            .frame(height: 250)
            .chartPlotStyle { plotArea in
                plotArea
                    .clipShape(Rectangle())
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { chartScale = max($0, 0.5) }
            )


        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2),
                radius: 8, x: 0, y: 4)
    }

    // Helper to clip/interpolate pace data
    private func clippedPaceData(from paceData: [PaceData], threshold: Double) -> [PaceData] {
        guard let last = paceData.last, last.distanceKm >= threshold else { return [] }
        let clipped = paceData.filter { $0.distanceKm <= threshold }
        if let end = clipped.last, abs(end.distanceKm - threshold) < 0.001 {
            return clipped
        }
        if let before = paceData.last(where: { $0.distanceKm <= threshold }),
           let after  = paceData.first(where: { $0.distanceKm > threshold }) {
            let frac = (threshold - before.distanceKm) / (after.distanceKm - before.distanceKm)
            let interp = before.paceMinPerKm + frac * (after.paceMinPerKm - before.paceMinPerKm)
            return clipped + [PaceData(distanceKm: threshold, paceMinPerKm: interp)]
        }
        return clipped
    }
}
