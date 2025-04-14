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
    init?(from data: [String: Any]) {
        // Use defaults if fields are missing for backward compatibility.
        let dayStr = data["day"] as? String ?? "Unknown Day"
        
        // Try to decode the distance from either a Double or an Int.
        var distance: Double = 0.0
        if let d = data["dailyDistance"] as? Double {
            distance = d
        } else if let i = data["dailyDistance"] as? Int {
            distance = Double(i)
        }
        
        self.day = dayStr
        self.dailyDistance = distance
        // For the completed flag, try Bool directly or default to false.
        self.isCompleted = data["completed"] as? Bool ?? false
        // Other fields might be missing in older data.
        self.dailyDate = (data["dailyDate"] as? Timestamp)?.dateValue()
        self.dailyRunType = data["dailyRunType"] as? String
        self.dailyEstimatedDuration = data["dailyEstimatedDuration"] as? String
        self.dailyWorkoutDetails = data["dailyWorkoutDetails"] as? [String]
    }
}


extension WeeklyPlan {
    init?(from data: [String: Any]) {
        // First, decode the dailyPlans field in a flexible manner.
        var dailyPlansData: [[String: Any]] = []
        if let arr = data["dailyPlans"] as? [[String: Any]] {
            dailyPlansData = arr
        } else if let dict = data["dailyPlans"] as? [String: Any] {
            // If stored as a dictionary keyed by index, sort by keys.
            let sortedKeys = dict.keys.sorted { (key1, key2) -> Bool in
                if let int1 = Int(key1), let int2 = Int(key2) {
                    return int1 < int2
                }
                return false
            }
            for key in sortedKeys {
                if let dayData = dict[key] as? [String: Any] {
                    dailyPlansData.append(dayData)
                }
            }
        }
        
        var decodedDailyPlans = [DailyPlan]()
        for dayData in dailyPlansData {
            // If decoding fails, we get a default DailyPlan with fallback values.
            if let day = DailyPlan(from: dayData) {
                decodedDailyPlans.append(day)
            }
        }
        
        // Use default values if these keys are missing.
        let weekNum = data["weekNumber"] as? Int ?? 0
        let weekTitle = data["weekTitle"] as? String ?? "Week \(weekNum)"
        let weeklyTotalWorkouts = data["weeklyTotalWorkouts"] as? Int ?? decodedDailyPlans.count
        
        var weeklyTotalDistance: Double = 0.0
        if let d = data["weeklyTotalDistance"] as? Double {
            weeklyTotalDistance = d
        } else if let i = data["weeklyTotalDistance"] as? Int {
            weeklyTotalDistance = Double(i)
        } else {
            // If the field is missing, calculate the sum from daily plans.
            weeklyTotalDistance = decodedDailyPlans.reduce(0.0) { $0 + $1.dailyDistance }
        }
        
        let weeklyDescription = data["weeklyDescription"] as? String ?? ""
        
        self.weekNumber = weekNum
        self.weekTitle = weekTitle
        self.weeklyTotalWorkouts = weeklyTotalWorkouts
        self.weeklyTotalDistance = weeklyTotalDistance
        self.weeklyDescription = weeklyDescription
        self.dailyPlans = decodedDailyPlans
    }
}

extension WeeklyPlan {
    /// Returns true if all active days (i.e. those with dailyDistance > 0) are marked as completed.
    var isCompleted: Bool {
        let activeDays = dailyPlans.filter { $0.dailyDistance > 0 }
        // If there are active days and all are completed, return true.
        return !activeDays.isEmpty && activeDays.allSatisfy { $0.isCompleted }
    }
}



extension UserRunningProgram {
    init?(from data: [String: Any]) {
        // Decode the required fields.
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let templateId = data["templateId"] as? String,
              let title = data["title"] as? String,
              let subtitle = data["subtitle"] as? String,
              let finishDateValue = data["finishDate"],
              let imageUrl = data["imageUrl"] as? String,
              let totalDistance = data["totalDistance"] as? Int,
              let planOverview = data["planOverview"] as? String,
              let experienceLevel = data["experienceLevel"] as? String,
              let username = data["username"] as? String,
              let startDateValue = data["startDate"],
              let overallCompletion = data["overallCompletion"] as? Int,
              let userProgramActive = data["userProgramActive"] as? Bool,
              let userProgramCompleted = data["userProgramCompleted"] as? Bool
        else {
            print("UserRunningProgram decoding failed: Missing required fields. Data: \(data)")
            return nil
        }
        
        // Convert finishDate and startDate from Timestamp (or Date)
        var finishDate: Date?
        if let ts = finishDateValue as? Timestamp {
            finishDate = ts.dateValue()
        } else if let dt = finishDateValue as? Date {
            finishDate = dt
        }
        var startDate: Date?
        if let ts = startDateValue as? Timestamp {
            startDate = ts.dateValue()
        } else if let dt = startDateValue as? Date {
            startDate = dt
        }
        guard let fDate = finishDate, let sDate = startDate else {
            print("UserRunningProgram decoding failed: Date conversion issue.")
            return nil
        }
        
        // Decode the target race time; if not present, default to 10800 seconds.
        let targetTime = data["targetTimeSeconds"] as? Double ?? 10800
        
        // Decode the weeklyPlan.
        // (Assuming you have similar logic elsewhere; here’s a simple placeholder.)
        let weeklyPlanArray: [WeeklyPlan]
        if let wpData = data["weeklyPlan"] as? [[String: Any]] {
            weeklyPlanArray = wpData.compactMap { WeeklyPlan(from: $0) }
        } else {
            weeklyPlanArray = []
        }
        
        // Assign values.
        self.id = id
        self.templateId = templateId
        self.title = title
        self.raceName = data["raceName"] as? String
        self.subtitle = subtitle
        self.finishDate = fDate
        self.imageUrl = imageUrl
        self.totalDistance = totalDistance
        self.planOverview = planOverview
        self.experienceLevel = experienceLevel
        self.weeklyPlan = weeklyPlanArray
        self.username = username
        self.startDate = sDate
        self.overallCompletion = overallCompletion
        self.userProgramActive = userProgramActive
        self.userProgramCompleted = userProgramCompleted
        self.targetTimeSeconds = targetTime
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
    DailyPlan(day: "Monday", distance: 5.0, runType: "Tempo"),
    DailyPlan(day: "Tuesday", distance: 7.5, runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 0.0, runType: nil), // Rest day
    DailyPlan(day: "Thursday", distance: 10.0, runType: "Long Run"),
    DailyPlan(day: "Friday", distance: 5.0, runType: "Intervals"),
    DailyPlan(day: "Saturday", distance: 12.0, runType: "Long Run"),
    DailyPlan(day: "Sunday", distance: 8.0, runType: "Easy Run")
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
// Use the same weekly plans (allWeeks) and total distance calculation as for the beginner 18-week program.
let sampleProgram = NewRunningProgram(
    id: UUID(), // A new ID is fine; stable Firestore ID comes from the title below
    title: "Sample Running Program",  // Must match your doc ID "sample-running-program"
    raceName: "Popular Beginner Plan",
    subtitle: "Build up from short runs to your full marathon",
    finishDate: Date().addingTimeInterval(60 * 60 * 24 * 7 * 18), // 18 weeks from now
    imageUrl: "https://via.placeholder.com/300?text=Beginner18Weeks",
    totalDistance: Int(totalDistanceOver18Weeks),
    planOverview: """
        This is an 18-week schedule matching the beginner plan. 
        We'll use it for testing dynamic scaling and customizations.
        """,
    experienceLevel: "Beginner",
    weeklyPlan: allWeeks // Same as your beginner plan's array
)

// 2) Write a small async function to overwrite 'sample-running-program' in Firestore.
@MainActor
func updateSampleRunningProgram() async {
    do {
        // 'updateTemplate' is your existing helper that calls setData(merge: false)
        // to overwrite the doc based on the template's title.
        try await updateTemplate(sampleProgram)
        print("Template 'sample-running-program' updated successfully.")
    } catch {
        print("Error updating sample running program: \(error.localizedDescription)")
    }
}




// Template for the weekly plans

// Week 1
let week1DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 1.0,  runType: "Run"),
    DailyPlan(day: "Saturday",  distance: 10.0,  runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 3.4,  runType: "Recovery Run")
]

// Week 2
let week2DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 11.0, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 3.4,  runType: "Recovery Run")
]

// Week 3
let week3DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 13.0, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 3.4,  runType: "Recovery Run")
]

// Week 4 (Easy Run distance increases to 6.4 km → Recovery ≈ 6.4*0.7 = 4.48 km, rounded to 4.5)
let week4DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 14.5, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 4.5,  runType: "Recovery Run")
]

// Week 5
let week5DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 16.0, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 4.5,  runType: "Recovery Run")
]

// Week 6 (Easy Run: 8.0 km → Recovery: 8.0*0.7 = 5.6 km)
let week6DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 19.3, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 5.6,  runType: "Recovery Run")
]

// Week 7 (Back to 4.8 km on easy days → Recovery: 3.4 km)
let week7DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 14.5, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 3.4,  runType: "Recovery Run")
]

// Week 8 (Race Week: Saturday is a half marathon; recovery is kept very short)
let week8DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,   runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 8.0,   runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 11.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 10.0,   runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,   runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 21.1,  runType: "Half Marathon"),
    DailyPlan(day: "Sunday",    distance: 3.0,   runType: "Recovery Run") // shorter recovery after race
]

// Week 9
let week9DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 10.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 14.5, runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 19.3, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 3.4,  runType: "Recovery Run")
]

// Week 10
let week10DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 16.0, runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 25.7, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 5.6,  runType: "Recovery Run")
]

// Week 11
let week11DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 29.0, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 5.6,  runType: "Recovery Run")
]

// Week 12
let week12DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 13.0, runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 19.3, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 4.5,  runType: "Recovery Run")
]

// Week 13
let week13DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 14.5, runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 29.0, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 5.6,  runType: "Recovery Run")
]

// Week 14
let week14DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 14.5, runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 22.5, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 5.6,  runType: "Recovery Run")
]

// Week 15
let week15DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 16.0, runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 8.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 32.2, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 5.6,  runType: "Recovery Run")
]

// Week 16
let week16DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 13.0, runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 19.3, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 4.5,  runType: "Recovery Run")
]

// Week 17
let week17DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 10.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 13.0, runType: "Long Run"),
    DailyPlan(day: "Sunday",    distance: 3.4,  runType: "Recovery Run")
]

// Week 18 (Race Week: Saturday is the full marathon)
let week18DailyPlans = [
    DailyPlan(day: "Monday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Tuesday",   distance: 5.0,  runType: "Easy Run"),
    DailyPlan(day: "Wednesday", distance: 6.0,  runType: "Easy Run"),
    DailyPlan(day: "Thursday",  distance: 3.2,  runType: "Long Run"),
    DailyPlan(day: "Friday",    distance: 0.0,  runType: "Rest"),
    DailyPlan(day: "Saturday",  distance: 42.2, runType: "Marathon"),
    DailyPlan(day: "Sunday",    distance: 3.4,  runType: "Recovery Run")
]


// 3) Combine all weekly plans into one array.
let allWeeks: [WeeklyPlan] = [
    week1DailyPlans,  week2DailyPlans,  week3DailyPlans,  week4DailyPlans,
    week5DailyPlans,  week6DailyPlans,  week7DailyPlans,  week8DailyPlans,
    week9DailyPlans,  week10DailyPlans, week11DailyPlans, week12DailyPlans,
    week13DailyPlans, week14DailyPlans, week15DailyPlans, week16DailyPlans,
    week17DailyPlans, week18DailyPlans
].enumerated().map { (index, dailyPlans) -> WeeklyPlan in
    let weekIndex = index + 1
    let totalDistance = dailyPlans.reduce(0.0) { $0 + $1.dailyDistance }
    let totalWorkouts = dailyPlans.filter { $0.dailyDistance > 0 }.count
    return WeeklyPlan(
        weekNumber: weekIndex,
        weekTitle: "Week \(weekIndex)",
        weeklyTotalWorkouts: totalWorkouts,
        weeklyTotalDistance: totalDistance,
        dailyPlans: dailyPlans,
        weeklyDescription: "Week \(weekIndex) of the 18-week beginner marathon plan."
    )
}

// And totalDistanceOver18Weeks is computed as:
let totalDistanceOver18Weeks = allWeeks.reduce(0.0) { $0 + $1.weeklyTotalDistance }


let advancedProgram = NewRunningProgram(
    title: "Advanced Marathon Running Program",
    raceName: "City Marathon 2025",
    subtitle: "Challenging workouts for seasoned runners",
    finishDate: Date().addingTimeInterval(60 * 60 * 24 * 120),
    imageUrl: "https://via.placeholder.com/300?text=Advanced",
    totalDistance: 600,
    planOverview: "High-intensity workouts and advanced training techniques to peak your performance.",
    experienceLevel: "Advanced",
    weeklyPlan: sampleWeeklyPlans // Adjust weekly plans if desired
)

