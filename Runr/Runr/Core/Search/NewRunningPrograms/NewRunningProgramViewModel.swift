//
//  NewRunningProgramViewModel.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import Foundation
import FirebaseFirestore

// Helper function to generate a custom document ID based on date and time
func generateDocumentId() -> String {
    let formatter = DateFormatter()
    // Format: day-month-year_hour-minute-secondam/pm (e.g., "1-4-2025_12-35-05pm")
    formatter.dateFormat = "d-M-yyyy_hh-mm-ssa"
    formatter.amSymbol = "am"
    formatter.pmSymbol = "pm"
    return formatter.string(from: Date())
}

// Function to convert your NewRunningProgram instance into a dictionary
func dictionaryFrom(program: NewRunningProgram) -> [String: Any] {
    let weeklyPlanData = program.weeklyPlan.map { week -> [String: Any] in
        let dailyPlansData = week.dailyPlans.map { day -> [String: Any] in
            return [
                "day": day.day,
                "dailyDate": day.dailyDate ?? NSNull(),
                "dailyDistance": day.dailyDistance,
                "dailyRunType": day.dailyRunType ?? "",
                "dailyEstimatedDuration": day.dailyEstimatedDuration ?? "",
                "dailyWorkoutDetails": day.dailyWorkoutDetails ?? [],
                "completed": day.isCompleted    // New field to store completion status
            ]
        }
        return [
            "weekNumber": week.weekNumber,
            "weekTitle": week.weekTitle,
            "weeklyTotalWorkouts": week.weeklyTotalWorkouts,
            "weeklyTotalDistance": week.weeklyTotalDistance,
            "dailyPlans": dailyPlansData,
            "weeklyDescription": week.weeklyDescription
        ]
    }
    
    let calculatedTotalDistance = program.weeklyPlan.reduce(0) { $0 + $1.weeklyTotalDistance }
    
    return [
        "id": program.id.uuidString,
        "title": program.title,
        "raceName": program.raceName ?? "",
        "subtitle": program.subtitle,
        "finishDate": program.finishDate,
        "imageUrl": program.imageUrl,
        "totalDistance": calculatedTotalDistance,
        "totalWeeks": program.weeklyPlan.count,
        "planOverview": program.planOverview,
        "experienceLevel": program.experienceLevel,
        "weeklyPlan": weeklyPlanData
    ]
}


// mark when a daily run is completed
func markDailyRunCompleted(for program: inout NewRunningProgram, documentId: String, weekIndex: Int, dayIndex: Int) {
    // Update the local model – set the completion flag to true.
    program.weeklyPlan[weekIndex].dailyPlans[dayIndex].isCompleted = true
    
    // Re-create the updated dictionary for the entire running program.
    let updatedData = dictionaryFrom(program: program)
    
    // Update the document in Firestore.
    let db = Firestore.firestore()
    db.collection("runningPrograms").document(documentId).setData(updatedData, merge: true) { error in
        if let error = error {
            print("Error updating daily run: \(error.localizedDescription)")
        } else {
            print("Daily run automatically marked as completed.")
        }
    }
}

// MARK: – Convenience wrapper (no args)
func markDailyRunCompletedHelper() {
    // **You said not to worry about sample data**, so we’ll just
    // use your sampleProgram and a dummy document ID here.
    var program = sampleProgram
    let documentId = generateDocumentId()
    
    // If you want a different week/day, adjust these:
    let weekIndex = 0
    let dayIndex = 0
    
    markDailyRunCompleted(
        for: &program,
        documentId: documentId,
        weekIndex: weekIndex,
        dayIndex: dayIndex
    )
}



// Function to save the running program into Firestore under a top-level collection "runningPrograms"
func saveRunningProgram(_ program: NewRunningProgram) {
    let db = Firestore.firestore()
    let data = dictionaryFrom(program: program)
    
    // Debug: print the weeklyPlan count
    if let weeklyPlanArray = data["weeklyPlan"] as? [[String: Any]] {
        print("Number of weeks to save: \(weeklyPlanArray.count)")
    }
    
    let documentId = generateDocumentId()
    
    db.collection("runningPrograms").document(documentId).setData(data) { error in
        if let error = error {
            print("Error saving running program: \(error.localizedDescription)")
        } else {
            print("Running program saved successfully!")
        }
    }
}

