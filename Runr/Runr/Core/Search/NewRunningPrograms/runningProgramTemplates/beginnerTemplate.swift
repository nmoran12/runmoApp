//
//  beginnerTemplate.swift
//  Runr
//
//  Created by Noah Moran on 14/4/2025.
//

import Foundation
import SwiftUI

// MARK: - Beginner Running Program Templates

struct BeginnerTemplates {
    
    /// Creates a basic beginner marathon program with a 6‐month duration.
    static func createBeginnerProgram(sampleWeeklyPlans: [WeeklyPlan]) -> NewRunningProgram {
        return NewRunningProgram(
            title: "Beginner Marathon Running Program",
            raceName: "City Marathon 2025",
            subtitle: "A step-by-step program for new runners",
            finishDate: Date().addingTimeInterval(60 * 60 * 24 * 180), // approx. 6 months from now
            imageUrl: "https://via.placeholder.com/300?text=Beginner",
            totalDistance: 400,
            planOverview: "A program designed for those new to marathon training. Gradually build stamina and endurance.",
            experienceLevel: "Beginner",
            weeklyPlan: sampleWeeklyPlans // Supply your weekly plan array here
        )
    }
    
    /// Creates an 18-week beginner marathon program using the complete weekly plan.
    static func create18WeekBeginnerProgram(allWeeks: [WeeklyPlan], totalDistanceOver18Weeks: Double) -> NewRunningProgram {
        return NewRunningProgram(
            id: UUID(),
            title: "18-Week Beginner Marathon Program",
            raceName: "Popular Beginner Plan",
            subtitle: "Build up from short runs to your full marathon",
            finishDate: Date().addingTimeInterval(60 * 60 * 24 * 7 * 18), // 18 weeks from now
            imageUrl: "https://via.placeholder.com/300?text=Beginner18Weeks",
            totalDistance: Int(totalDistanceOver18Weeks),
            planOverview: """
                This 18-week beginner marathon training plan features gradual progression and two milestone races: 
                a half marathon (Week 8) and a full marathon (Week 18). Each week includes three runs, two rest days, 
                one long run, and a cross-training day.
                """,
            experienceLevel: "Beginner",
            weeklyPlan: allWeeks
        )
    }
    
    /// Asynchronously updates the beginner marathon template in Firestore.
    @MainActor
    static func updateBeginnerMarathonTemplate(using updatedProgram: NewRunningProgram) async {
        do {
            try await updateTemplate(updatedProgram)
            print("Template 'beginner-marathon-running-program' updated successfully.")
        } catch {
            print("Error updating beginner marathon template: \(error.localizedDescription)")
        }
    }
}
