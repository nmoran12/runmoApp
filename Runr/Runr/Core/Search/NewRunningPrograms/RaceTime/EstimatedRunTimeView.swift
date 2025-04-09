//
//  EstimatedRunTimeView.swift
//  Runr
//
//  Created by Noah Moran on 8/4/2025.
//

import SwiftUI

struct EstimatedRunTimeView: View {
    /// The target race distance in kilometers (e.g., 10 for 10K, 42.195 for Marathon)
    let targetDistance: Double

    @StateObject private var bestEffortsVM = BestEffortsViewModel()
    private let predictor = RaceTimePredictor()
    
    @State private var estimatedTime: String = "Calculating..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimated Time for \(formattedDistance(targetDistance))")
                .font(.headline)
            Text(estimatedTime)
                .font(.title)
                .foregroundColor(.blue)
        }
        .padding()
        .onAppear {
            // Load personal bests from Firestore.
            bestEffortsVM.loadPersonalBests()
        }
        // Update the estimate when the personal bests are fetched.
        .onChange(of: bestEffortsVM.bestEfforts) { efforts in
            updateEstimate(with: efforts)
        }
    }
    
    /// Chooses the personal best for the 5K event and updates the estimated time.
    private func updateEstimate(with efforts: [BestEffortsViewModel.BestEffort]) {
        // Here we're using the 5K effort; if not found, you might choose another event
        if let fiveKEffort = efforts.first(where: { $0.distance.lowercased().contains("5k") }) {
            let knownDistanceKm = 5.0  // 5K event means 5.0 km
            let knownTimeSeconds = fiveKEffort.time
            // Calculate estimated time for targetDistance using Riegel's Formula.
            let estimatedSeconds = predictor.predictTime(d1: knownDistanceKm, t1: knownTimeSeconds, d2: targetDistance)
            estimatedTime = predictor.formatTime(seconds: estimatedSeconds)
        } else {
            estimatedTime = "No 5K personal best found"
        }
    }
    
    /// Returns a friendly string for target distances.
    private func formattedDistance(_ distance: Double) -> String {
        // Use simple ranges to map distances to common names.
        switch distance {
        case 42.0...:
            return "Marathon"
        case 21.0..<42.0:
            return "Half Marathon"
        default:
            return "\(distance)K"
        }
    }
}

#Preview {
    // For preview purposes, estimating time for a 10K race.
    EstimatedRunTimeView(targetDistance: 42.2)
}
