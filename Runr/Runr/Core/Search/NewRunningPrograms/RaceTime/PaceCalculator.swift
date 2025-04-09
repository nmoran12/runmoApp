//
//  PaceCalculator.swift
//  Runr
//
//  Created by Noah Moran on 8/4/2025.
//

import Foundation

// Define run types in a type-safe way.
enum RunType: String, CaseIterable {
    case tempo = "Tempo"
    case easyRun = "Easy Run"
    case longRun = "Long Run"
    case intervals = "Intervals"
}

struct PaceCalculator {
    /// Calculates the marathon pace (in seconds per kilometer) given a target race time.
    /// - Parameter targetTimeSeconds: The target marathon time in seconds.
    /// - Returns: The marathon pace in seconds per km.
    static func marathonPace(targetTimeSeconds: Double) -> Double {
        let marathonDistance = 42.195
        return targetTimeSeconds / marathonDistance
    }
    
    /// Returns the recommended pace range (as lower and upper bounds, in seconds per km)
    /// for a given run type by applying offsets to the marathon pace.
    /// - Parameters:
    ///   - runType: The type of run as a RunType enum.
    ///   - marathonPaceSec: The base marathon pace in seconds per km.
    /// - Returns: A tuple (lowerBound, upperBound) representing the recommended pace range.
    static func recommendedPaceRange(for runType: RunType, marathonPaceSec: Double) -> (Double, Double) {
        switch runType {
        case .easyRun:
            return (marathonPaceSec + 30, marathonPaceSec + 60)  // 30 to 60 sec slower than marathon pace.
        case .tempo:
            return (marathonPaceSec - 20, marathonPaceSec - 10)  // 20 to 10 sec faster than marathon pace.
        case .longRun:
            return (marathonPaceSec + 18, marathonPaceSec + 56)  // 18 to 56 sec slower than marathon pace.
        case .intervals:
            return (marathonPaceSec - 40, marathonPaceSec - 30)  // 40 to 30 sec faster than marathon pace.
        }
    }
    
    /// Formats seconds per kilometer into a "m:ss" formatted string.
    /// - Parameter secondsPerKm: Pace in seconds per km.
    /// - Returns: A formatted string like "5:30".
    static func formatPace(secondsPerKm: Double) -> String {
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Returns a formatted recommended pace range for the specified run type given a target race time.
    /// - Parameters:
    ///   - runType: The run type (e.g. .tempo, .easyRun, .longRun, .intervals).
    ///   - targetTimeSeconds: The user’s target marathon time in seconds.
    /// - Returns: A formatted string for the recommended pace range (e.g. "4:35 – 4:45 min/km").
    static func formattedRecommendedPace(for runType: RunType, targetTimeSeconds: Double) -> String {
        let basePace = marathonPace(targetTimeSeconds: targetTimeSeconds)
        let (lowerBound, upperBound) = recommendedPaceRange(for: runType, marathonPaceSec: basePace)
        return "\(formatPace(secondsPerKm: lowerBound)) – \(formatPace(secondsPerKm: upperBound))"
    }
}

