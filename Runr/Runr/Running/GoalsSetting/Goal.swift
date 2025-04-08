//
//  Goal.swift
//  Runr
//
//  Created by Noah Moran on 2/4/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore // Import Timestamp

struct Goal: Identifiable, Equatable {
    let id: String // Use Firestore document ID
    var title: String
    var category: String

    var targetRaw: String = "" // Original string like "11 km" (optional)
    var targetValue: Double = 0.0
    var targetUnit: String = ""
    var period: String = "allTime" // Default period if not specified

    var currentProgress: Double = 0.0
    var isCompleted: Bool = false
    var lastResetDate: Date? // Use Date in Swift, convert from Timestamp

    // Add computed property for display formatting if needed
    var displayProgress: String {
        String(format: "%.1f", currentProgress) // Example: format to 1 decimal
    }
    var displayTarget: String {
        String(format: "%.1f", targetValue) // Example: format to 1 decimal
    }
    var progressFraction: Double {
        guard targetValue > 0 else { return 0.0 }
        return min(currentProgress / targetValue, 1.0) // Clamp between 0 and 1
    }

    // Initializer to handle Firestore data
    init(id: String, data: [String: Any]) {
        self.id = id
        self.title = data["title"] as? String ?? "Untitled Goal"
        self.category = data["category"] as? String ?? "Unknown"
        self.targetRaw = data["targetRaw"] as? String ?? ""
        self.targetValue = data["targetValue"] as? Double ?? 0.0
        self.targetUnit = data["targetUnit"] as? String ?? ""
        self.period = data["period"] as? String ?? "allTime"
        self.currentProgress = data["currentProgress"] as? Double ?? 0.0
        self.isCompleted = data["isCompleted"] as? Bool ?? false
        self.lastResetDate = (data["lastResetDate"] as? Timestamp)?.dateValue()
    }

    // Convenience init for creating NEW goals before upload (may need adjustment)
    init(id: UUID = UUID(), title: String, category: String, targetRaw: String = "", targetValue: Double = 0, targetUnit: String = "", period: String = "allTime") {
         self.id = id.uuidString // Use UUID temporarily if needed before Firestore ID
         self.title = title
         self.category = category
         self.targetRaw = targetRaw
         self.targetValue = targetValue
         self.targetUnit = targetUnit
         self.period = period
         // Defaults for new goals
         self.currentProgress = 0.0
         self.isCompleted = false
         self.lastResetDate = nil // Will be set on first update for periodic goals
     }

     // Conformance to Equatable based on ID
     static func == (lhs: Goal, rhs: Goal) -> Bool {
         lhs.id == rhs.id
     }
}
