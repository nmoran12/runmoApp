//
//  SplitBarChartView.swift
//  Runr
//
//  Created by Noah Moran on 25/3/2025.
//

import SwiftUI
import Charts

struct SplitBarChartView: View {
    let splits: [Split]
    
    var body: some View {
        Chart(splits, id: \.splitNumber) { split in
            BarMark(
                x: .value("KM", "KM \(split.splitNumber)"),
                y: .value("Pace", split.pace / 60.0) // convert to minutes
            )
            .foregroundStyle(.blue)
        }
        .chartYAxisLabel("Pace (min/km)")
        .chartXAxisLabel("Kilometer")
        .frame(height: 200)
        .padding()
    }
}


#Preview {
    SplitBarChartView(splits: [
        Split(splitNumber: 1, distanceMeters: 1000, splitTime: 300),
        Split(splitNumber: 2, distanceMeters: 1000, splitTime: 320)
    ])
}

