//
//  RaceTimePredictor.swift
//  Runr
//
//  Created by Noah Moran on 8/4/2025.
//

import Foundation

struct RaceTimePredictor {
    /// Uses Riegel's formula to estimate race time for a target distance.
    ///
    /// - Parameters:
    ///   - d1: Known performance distance in kilometers.
    ///   - t1: Known performance time in seconds for distance d1.
    ///   - d2: Target race distance in kilometers.
    /// - Returns: Estimated time in seconds for distance d2.
    func predictTime(d1: Double, t1: Double, d2: Double) -> Double {
        let exponent = 1.06
        return t1 * pow((d2 / d1), exponent)
    }
    
    /// Formats a time value in seconds into a string of the form hh:mm:ss.
    ///
    /// - Parameter seconds: Time in seconds.
    /// - Returns: A formatted time string.
    func formatTime(seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
