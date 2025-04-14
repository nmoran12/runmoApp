//
//  intermediateTemplate.swift
//  Runr
//
//  Created by Noah Moran on 14/4/2025.
//

import Foundation
import SwiftUI

// MARK: - Intermediate Running Program Template

struct IntermediateTemplates {
    
    /// Creates an intermediate marathon program with updated values.
    static func createIntermediateProgram(allWeeks: [WeeklyPlan]) -> NewRunningProgram {
        return NewRunningProgram(
            id: UUID(),
            title: "Intermediate Marathon Running Program",
            raceName: "City Marathon 2025",
            subtitle: "For runners looking to improve performance",
            finishDate: Date().addingTimeInterval(60 * 60 * 24 * 150), // e.g., 150 days from now
            imageUrl: "https://via.placeholder.com/300?text=Intermediate",
            totalDistance: 500,
            planOverview: """
                This intermediate training program builds upon the sample running program template.
                It is designed for runners who already have a base level of fitness and now want to
                improve performance with additional speed, endurance, and strength workouts.
                """,
            experienceLevel: "Intermediate",
            // You can reuse the same weekly plan (allWeeks) or customize it further.
            weeklyPlan: allWeeks
        )
    }
    
    /// Asynchronously updates the intermediate marathon template in Firestore.
    @MainActor
    static func updateIntermediateMarathonTemplate(using intermediateProgram: NewRunningProgram) async {
        do {
            try await updateTemplate(intermediateProgram)
            print("Template 'intermediate-marathon-running-program' updated successfully.")
        } catch {
            print("Error updating intermediate marathon template: \(error.localizedDescription)")
        }
    }
}
