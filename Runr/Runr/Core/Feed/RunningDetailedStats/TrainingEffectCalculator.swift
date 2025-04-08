//
//  TrainingEffectCalculator.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import Foundation
import HealthKit

struct TrainingEffectCalculator {
    let hrRest: Double    // e.g. 60
    let hrMax: Double     // e.g. 190
    let b: Double         // 1.92 for men, 1.67 for women
    
    /// Compute TRIMP for a run
    func computeTRIMP(avgHR: Double, durationMinutes: Double) -> Double {
        let deltaHR = (avgHR - hrRest) / (hrMax - hrRest)
        guard deltaHR > 0 else { return 0 }
        return durationMinutes * deltaHR * exp(b * deltaHR)
    }
    
    /// Map TRIMP onto a 1–5 Training Effect scale
    func trainingEffect(from trimp: Double) -> Double {
        // Choose a “benchmark” TRIMP for TE=5.0; e.g. 100
        let trimpMax: Double = 100
        // Linear mapping, clamped 1.0–5.0
        let te = 1.0 + 4.0 * min(trimp / trimpMax, 1.0)
        return round(te * 10) / 10  // one decimal place
    }
}
