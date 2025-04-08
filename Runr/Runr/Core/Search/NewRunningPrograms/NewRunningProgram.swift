//
//  NewRunningProgram.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

// Updated DailyPlan model to include additional properties
struct DailyPlan: Hashable, Identifiable {
    let id = UUID()
    let day: String
    let dailyDate: Date?
    let dailyDistance: Double
    let dailyRunType: String?
    let dailyEstimatedDuration: String?
    let dailyWorkoutDetails: [String]?
    var isCompleted: Bool

    // Keep your existing memberwise init
    init(
        day: String,
        date: Date? = nil,
        distance: Double,
        runType: String? = nil,
        estimatedDuration: String? = nil,
        workoutDetails: [String]? = nil,
        isCompleted: Bool = false
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
    var id = UUID()
    let weekNumber: Int
    let weekTitle: String
    let weeklyTotalWorkouts: Int
    let weeklyTotalDistance: Double
    var dailyPlans: [DailyPlan]
    let weeklyDescription: String

     // Add a basic memberwise init if needed (often generated automatically for structs)
      init(id: UUID = UUID(), weekNumber: Int, weekTitle: String, weeklyTotalWorkouts: Int, weeklyTotalDistance: Double, dailyPlans: [DailyPlan], weeklyDescription: String) {
         self.id = id
         self.weekNumber = weekNumber
         self.weekTitle = weekTitle
         self.weeklyTotalWorkouts = weeklyTotalWorkouts
         self.weeklyTotalDistance = weeklyTotalDistance
         self.dailyPlans = dailyPlans
         self.weeklyDescription = weeklyDescription
     }
}

struct NewRunningProgram: Identifiable {
    let id: UUID // Use UUID if that's what you store or need internally
    let title: String
    let raceName: String?
    let subtitle: String
    let finishDate: Date
    let imageUrl: String
    let totalDistance: Int // Assuming this comes from Firestore now
    let planOverview: String
    let experienceLevel: String
    var weeklyPlan: [WeeklyPlan]

    var totalWeeks: Int {
        return weeklyPlan.count
    }

     // Add a basic memberwise init if needed
      init(id: UUID = UUID(), title: String, raceName: String? = nil, subtitle: String, finishDate: Date, imageUrl: String, totalDistance: Int, planOverview: String, experienceLevel: String, weeklyPlan: [WeeklyPlan]) {
         self.id = id
         self.title = title
         self.raceName = raceName
         self.subtitle = subtitle
         self.finishDate = finishDate
         self.imageUrl = imageUrl
         self.totalDistance = totalDistance
         self.planOverview = planOverview
         self.experienceLevel = experienceLevel
         self.weeklyPlan = weeklyPlan
     }
}


// MARK: - Firestore Decoding Initializers

extension DailyPlan {
    // Failable initializer to decode from Firestore dictionary
    init?(from data: [String: Any]) {
        // Guard only the truly REQUIRED fields that cause init to fail if missing
        guard let dayStr = data["day"] as? String,
              let distance = data["dailyDistance"] as? Double
              // REMOVE 'completed' from the guard
        else {
            print("Error decoding DailyPlan: Missing required fields (day, dailyDistance). Data: \(data)")
            return nil // Initialization failed if day or distance are missing
        }

        // Assign required properties
        // self.id = UUID() // Let Swift auto-generate UUID for the struct instance
        self.day = dayStr
        self.dailyDistance = distance

        // --- Assign 'isCompleted' AFTER the guard, providing default value ---
        self.isCompleted = data["completed"] as? Bool ?? false // Defaults to false if nil or wrong type

        // Assign other optional properties
        self.dailyDate = (data["dailyDate"] as? Timestamp)?.dateValue()
        self.dailyRunType = data["dailyRunType"] as? String
        self.dailyEstimatedDuration = data["dailyEstimatedDuration"] as? String
        self.dailyWorkoutDetails = data["dailyWorkoutDetails"] as? [String]
     }
 }

extension WeeklyPlan {
    // Failable initializer to decode from Firestore dictionary
     init?(from data: [String: Any]) {
        guard let weekNum = data["weekNumber"] as? Int,
              let weekTitle = data["weekTitle"] as? String,
              let workouts = data["weeklyTotalWorkouts"] as? Int,
              let distance = data["weeklyTotalDistance"] as? Double,
              let description = data["weeklyDescription"] as? String,
              let dailyPlansData = data["dailyPlans"] as? [[String: Any]] // Expect an array of dictionaries
        else {
             print("Error decoding WeeklyPlan: Missing required fields or type mismatch. Data: \(data)")
             return nil
        }

        // Assign properties
        // self.id = UUID() // Generate a new UUID for the struct instance
        self.weekNumber = weekNum
        self.weekTitle = weekTitle
        self.weeklyTotalWorkouts = workouts
        self.weeklyTotalDistance = distance
        self.weeklyDescription = description
        // Decode the nested array of DailyPlan dictionaries
        self.dailyPlans = dailyPlansData.compactMap { DailyPlan(from: $0) }
     }
 }

 extension NewRunningProgram {
    // Failable initializer to decode from Firestore dictionary
     init?(from data: [String: Any]) {
         // Safely unwrap all required fields
         guard let idString = data["id"] as? String, // Expecting UUID as String from Firestore
               let id = UUID(uuidString: idString), // Convert String back to UUID
               let title = data["title"] as? String,
               let subtitle = data["subtitle"] as? String,
               let finishTimestamp = data["finishDate"] as? Timestamp, // Get Timestamp
               let imageUrl = data["imageUrl"] as? String,
               let totalDistance = data["totalDistance"] as? Int, // Assuming stored as Int
               let planOverview = data["planOverview"] as? String,
               let experienceLevel = data["experienceLevel"] as? String,
               let weeklyPlanData = data["weeklyPlan"] as? [[String: Any]] // Array of Dictionaries
         else {
             print("Error decoding NewRunningProgram: Missing required fields or type mismatch. Data: \(data)")
             return nil // Initialization failed
         }

         // Assign properties
         self.id = id
         self.title = title
         self.raceName = data["raceName"] as? String // Optional field
         self.subtitle = subtitle
         self.finishDate = finishTimestamp.dateValue() // Convert Timestamp to Date
         self.imageUrl = imageUrl
         self.totalDistance = totalDistance
         self.planOverview = planOverview
         self.experienceLevel = experienceLevel

         // Decode nested weekly plans using their initializer
         self.weeklyPlan = weeklyPlanData.compactMap { WeeklyPlan(from: $0) }
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
