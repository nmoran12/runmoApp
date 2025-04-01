//
//  TagsManager.swift
//  Runr
//
//  Created by Noah Moran on 31/3/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

struct TagsManager {
    /// Computes dynamic tags based on the provided runs.
    /// Note: You can modify thresholds as needed.
    static func computeTags(from runs: [RunData]) -> [String] {
        var tags = [String]()
        
        // Existing Tags:
        
        // Marathon Runner: if any run is at least a marathon distance (42,195 m)
        if runs.contains(where: { $0.distance >= 42_195 }) {
            tags.append("Marathon Runner")
        }
        
        // 5K Speed Demon: if any 5K (or longer) run's equivalent 5K time is under 15 minutes (900 s)
        let fiveKRuns = runs.filter { $0.distance >= 5000 }
        if let fastestFiveK = fiveKRuns.min(by: {
            ($0.elapsedTime * (5000 / $0.distance)) < ($1.elapsedTime * (5000 / $1.distance))
        }), fastestFiveK.elapsedTime * (5000 / fastestFiveK.distance) < 900 {
            tags.append("5K Speed Demon")
        }
        
        // 10K Runner: if any 10K run's equivalent time is under 40 minutes (2400 s)
        let tenKRuns = runs.filter { $0.distance >= 10_000 }
        if let fastestTenK = tenKRuns.min(by: {
            ($0.elapsedTime * (10_000 / $0.distance)) < ($1.elapsedTime * (10_000 / $1.distance))
        }), fastestTenK.elapsedTime * (10_000 / fastestTenK.distance) < 2400 {
            tags.append("10K Runner")
        }
        
        // Elite Marathoner: if any marathon run (>=42,195 m) has an equivalent time under 2:30 (9000 s)
        let marathonRuns = runs.filter { $0.distance >= 42_195 }
        if let eliteMarathon = marathonRuns.min(by: {
            ($0.elapsedTime * (42_195 / $0.distance)) < ($1.elapsedTime * (42_195 / $1.distance))
        }), eliteMarathon.elapsedTime * (42_195 / eliteMarathon.distance) < 9000 {
            tags.append("Elite Marathoner")
        }
        
        // Ultra Legend: if any run is at least 100 km (100,000 m) and its equivalent time is under 12 hours (43,200 s)
        let ultraRuns = runs.filter { $0.distance >= 100_000 }
        if let ultraLegend = ultraRuns.min(by: {
            ($0.elapsedTime * (100_000 / $0.distance)) < ($1.elapsedTime * (100_000 / $1.distance))
        }), ultraLegend.elapsedTime * (100_000 / ultraLegend.distance) < 43_200 {
            tags.append("Ultra Legend")
        }
        
        // Compute overall totals for additional tags
        let totalDistanceMeters = runs.reduce(0, { $0 + $1.distance })
        let totalDistanceKm = totalDistanceMeters / 1000.0
        let totalElapsedTime = runs.reduce(0, { $0 + $1.elapsedTime })
        let overallAveragePace = totalDistanceKm > 0 ? (totalElapsedTime / totalDistanceKm) / 60.0 : Double.infinity
        
        // Pace Setter: if at least 10 runs and overall average pace is under 5 min/km
        if runs.count >= 10 && overallAveragePace < 5.0 {
            tags.append("Pace Setter")
        }
        
        // Distance Dominator: if cumulative distance is at least 1000 km
        if totalDistanceKm >= 1000 {
            tags.append("Distance Dominator")
        }
        
        // Veteran Runner: if the user has completed at least 50 runs
        if runs.count >= 50 {
            tags.append("Veteran Runner")
        }
        
        // Consistent Runner: if the user has run on 7 or more distinct days
        let distinctDays = Set(runs.map { Calendar.current.startOfDay(for: $0.date) })
        if distinctDays.count >= 7 {
            tags.append("Consistent Runner")
        }
        
        return tags
    }
    
    /// Updates the current user's tags in Firestore.
    static func updateUserTags(_ tags: [String]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await Firestore.firestore().collection("users").document(uid).updateData(["tags": tags])
    }
    
    /// Creates a badge count to show when user has more tags than can be displayed
    static func getBadgeCount(for tags: [String], maxVisibleTags: Int) -> Int? {
        let extraTags = tags.count - maxVisibleTags
        return extraTags > 0 ? extraTags : nil
    }
}
