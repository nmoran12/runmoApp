//
//  PaceLineChartView.swift
//  Runr
//
//  Created by Noah Moran on 25/3/2025.
//

import SwiftUI
import Charts

struct PaceLineChartView: View {
    let paceData: [PaceData]
    
    var body: some View {
        Chart(paceData) { dataPoint in
            LineMark(
                x: .value("Distance (km)", dataPoint.distanceKm),
                y: .value("Pace (min/km)", dataPoint.paceMinPerKm)
            )
            .interpolationMethod(.cardinal)
            .foregroundStyle(.blue)
            
            AreaMark(
                x: .value("Distance (km)", dataPoint.distanceKm),
                y: .value("Pace (min/km)", dataPoint.paceMinPerKm)
            )
            .foregroundStyle(.blue.opacity(0.3))
        }
        .chartXAxisLabel("Distance (km)")
        .chartYAxisLabel("Pace (min/km)")
        .frame(height: 200)
        .padding()
    }
}


#Preview {
    PaceLineChartView(paceData: [
        PaceData(distanceKm: 1.0, paceMinPerKm: 5.0),
        PaceData(distanceKm: 2.0, paceMinPerKm: 4.8),
        PaceData(distanceKm: 3.0, paceMinPerKm: 5.2)
    ])
}

