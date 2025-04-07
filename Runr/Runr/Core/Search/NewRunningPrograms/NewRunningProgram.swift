//
//  NewRunningProgram.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import Foundation
import SwiftUI

// Updated DailyPlan model to include additional properties
struct DailyPlan: Hashable, Identifiable {
    let id = UUID()
    let day: String
    let dailyDate: Date?
    let dailyDistance: Double
    let dailyRunType: String?
    let dailyEstimatedDuration: String?
    let dailyWorkoutDetails: [String]?
    var isCompleted: Bool  // New property
    
    init(
        day: String,
        date: Date? = nil,
        distance: Double,
        runType: String? = nil,
        estimatedDuration: String? = nil,
        workoutDetails: [String]? = nil,
        isCompleted: Bool = false  // Default to false
    ) {
        self.day = day
        self.dailyDate = date
        self.dailyDistance = distance
        self.dailyRunType = runType
        self.dailyEstimatedDuration = estimatedDuration
        self.dailyWorkoutDetails = workoutDetails
        self.isCompleted = isCompleted
    }
}

struct WeeklyPlan: Identifiable {
    let id = UUID()
    let weekNumber: Int // e.g. '1', '2', '3', etc.
    let weekTitle: String      // e.g., "Week 1", "Week 2", etc.
    let weeklyTotalWorkouts: Int     // total number of workouts in that week
    let weeklyTotalDistance: Double  // total kilometers to run in that week
    var dailyPlans: [DailyPlan] // breakdown day by day
    let weeklyDescription: String // a short description to describe what we will do in that week
}

struct NewRunningProgram: Identifiable {
    let id = UUID()
    let title: String // title for running program
    let raceName: String? // name of race if it is for a race (e.g. Sydney Marathon)
    let subtitle: String // title under the title
    let finishDate: Date // when the program will finish
    let imageUrl: String // image to display
    let totalDistance: Int // total distancae that will be ran across the entire running program (in km's)
    let planOverview: String // short overview of what the running program is about
    let experienceLevel: String // beginner, advanced, intermediate, pro, etc.
    var weeklyPlan: [WeeklyPlan]
    
    // Computed property to derive totalWeeks from weeklyPlan.count
        var totalWeeks: Int {
            return weeklyPlan.count
        }
}

// SAMPLE DATA FOR TESTING PURPOSES
// Sample daily plans for the weekly plan card view
// Create sample daily plans that will be reused in each week
let sampleDailyPlans = [
    DailyPlan(day: "Monday", distance: 5.0),
    DailyPlan(day: "Tuesday", distance: 7.5),
    DailyPlan(day: "Wednesday", distance: 0.0), // rest day
    DailyPlan(day: "Thursday", distance: 10.0),
    DailyPlan(day: "Friday", distance: 100.0),
    DailyPlan(day: "Saturday", distance: 12.0),
    DailyPlan(day: "Sunday", distance: 8.0)
]

// Generate multiple WeeklyPlan instances using a loop
let sampleWeeklyPlans: [WeeklyPlan] = (1...6).map { weekNumber in
    let weeklyTotalDistance = sampleDailyPlans.reduce(0) { $0 + $1.dailyDistance }
    return WeeklyPlan(
        weekNumber: weekNumber,
        weekTitle: "Week \(weekNumber)",
        weeklyTotalWorkouts: 6,
        weeklyTotalDistance: weeklyTotalDistance,
        dailyPlans: sampleDailyPlans,
        weeklyDescription: "This is the description for week \(weekNumber)"
    )
}

// Create a sample running program that now includes multiple weeks
let sampleProgram = NewRunningProgram(
    title: "Sample Running Program",
    raceName: "Boston Marathon 2025",
    subtitle: "A new running challenge",
    finishDate: Date(),
    imageUrl: "https://via.placeholder.com/300",
    totalDistance: 500,
    planOverview: "This is a sample overview of the running program. It details the plan and what you can expect.",
    experienceLevel: "Beginner",
    weeklyPlan: sampleWeeklyPlans
)
