//
//  NewRunningProgramViewModel.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import Foundation
import FirebaseFirestore
import Combine

class NewRunningProgramViewModel: ObservableObject {
    
    @Published var currentProgram: NewRunningProgram?
    @Published var currentUserProgram: UserRunningProgram?
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    @Published var hasActiveProgram: Bool = false
    @Published var targetTimeSeconds: Double = 10800  // Default or initial value
    @Published var todaysDailyPlanOverride: DailyPlan? = nil

    
    // Store the STABLE document ID for the currently loaded template program
    @Published private(set) var currentStableDocumentId: String? = nil
    private let db = Firestore.firestore()
    
    // To notify views when a program is updated (e.g. completion status)
    let programUpdated = PassthroughSubject<Void, Never>()
    
    /// Loads the active user program for the given username from "userRunningPrograms"
    @MainActor
    func loadActiveUserProgram(for username: String) async {
        do {
            let querySnapshot = try await db.collection("userRunningPrograms")
                .whereField("username", isEqualTo: username)
                .whereField("userProgramActive", isEqualTo: true)
                .getDocuments()
            if let document = querySnapshot.documents.first {
                let data = document.data()
                if let loadedProgram = UserRunningProgram(from: data) {
                    self.currentUserProgram = loadedProgram
                    // Update the view model's targetTimeSeconds with the loaded value:
                    self.targetTimeSeconds = loadedProgram.targetTimeSeconds
                    print("Loaded active user program for \(username) with targetTimeSeconds: \(loadedProgram.targetTimeSeconds)")
                } else {
                    print("Error: Failed to decode active user program for \(username)")
                }
            } else {
                print("No active user program found for \(username)")
            }
        } catch {
            print("Error loading active user program: \(error.localizedDescription)")
        }
    }


    
    // MARK: - Template Loading
    
    // Load a template running program from the "runningProgramTemplates" collection.
    @MainActor
    func loadProgram(titled programTitle: String) async {
        guard !programTitle.isEmpty else {
            print("PROGRAM LOAD ERROR: Program title is empty.")
            self.currentProgram = nil
            self.currentStableDocumentId = nil
            return
        }
        
        isLoading = true
        error = nil
        self.currentProgram = nil
        
        // Generate the stable document ID based on the title
        let stableId = generateStableDocumentId(for: programTitle)
        self.currentStableDocumentId = stableId
        
        print("PROGRAM LOAD: Attempting to load program template with stable ID: \(stableId)")
        
        // Use the "runningProgramTemplates" collection for templates.
        let docRef = db.collection("runningProgramTemplates").document(stableId)
        
        do {
            let document = try await docRef.getDocument()
            if document.exists, let data = document.data() {
                self.currentProgram = NewRunningProgram(from: data)
                print("PROGRAM LOAD: Successfully loaded template '\(programTitle)'")
            } else {
                print("PROGRAM LOAD WARNING: No template found with title '\(programTitle)' (ID: \(stableId)).")
                self.error = NSError(domain: "AppError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Running program template not found."])
            }
        } catch let fetchError {
            print("PROGRAM LOAD ERROR: Failed to fetch program template '\(programTitle)': \(fetchError.localizedDescription)")
            self.error = fetchError
        }
        isLoading = false
    }
    
    // MARK: - Creating a User Instance
    
    /// Creates a user-specific instance from a template and writes it to the "userRunningPrograms" collection.
    @MainActor
    func startUserRunningProgram(from template: NewRunningProgram, username: String) async {
        // Create a new user instance using the custom initializer.
        let userProgram = UserRunningProgram(from: template, username: username)
        let data = dictionaryFrom(userProgram: userProgram)
        
        // Save to the "userRunningPrograms" collection using the new instance ID.
        let docRef = db.collection("userRunningPrograms").document(userProgram.id.uuidString)
        
        do {
            try await docRef.setData(data, merge: false)
            print("USER PROGRAM STARTED: Instance created for \(username) based on template \(template.title)")
            // Save the user instance in the view model.
            self.currentUserProgram = userProgram
        } catch {
            print("Error starting user running program: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    // MARK: - Checking Active User Program
    @MainActor
    func checkActiveUserProgram(for username: String) async {
        do {
            let querySnapshot = try await db.collection("userRunningPrograms")
                .whereField("username", isEqualTo: username)
                .whereField("userProgramActive", isEqualTo: true)
                .getDocuments()
            
            hasActiveProgram = !querySnapshot.documents.isEmpty
            
            if hasActiveProgram {
                print("User \(username) already has an active running program.")
            } else {
                print("User \(username) does not have an active running program.")
            }
        } catch {
            print("Error checking active user program: \(error.localizedDescription)")
            hasActiveProgram = false
        }
    }
    
    // NEW: Function to update the user's target race time in Firestore.
        @MainActor
        func updateUserTargetTime(newTargetTime: Double) async {
            guard var userProgram = currentUserProgram else {
                print("No active user program to update target time.")
                return
            }
            // Update the targetTimeSeconds property in the user instance.
            userProgram.targetTimeSeconds = newTargetTime
            self.currentUserProgram = userProgram
            let docRef = db.collection("userRunningPrograms").document(userProgram.id.uuidString)
            let updatedData = dictionaryFrom(userProgram: userProgram)
            do {
                try await docRef.setData(updatedData, merge: false)
                print("Updated targetTimeSeconds in Firestore to \(newTargetTime)")
            } catch {
                print("Failed to update targetTimeSeconds: \(error.localizedDescription)")
            }
        }

    
    // MARK: - Updating Daily Completion for User Instance
    
    /// Updates a day's completion in the active user instance.
    @MainActor
    func markDailyRunCompleted(weekIndex: Int, dayIndex: Int, completed: Bool) async {
        guard var userProgram = currentUserProgram else {
            print("MARK COMPLETE ERROR: No active user instance to update.")
            return
        }
        guard userProgram.weeklyPlan.indices.contains(weekIndex),
              userProgram.weeklyPlan[weekIndex].dailyPlans.indices.contains(dayIndex) else {
            print("MARK COMPLETE ERROR: Invalid week (\(weekIndex)) or day (\(dayIndex)) index in user instance.")
            return
        }
        
        // Update the local user instance (which should be complete)
        userProgram.weeklyPlan[weekIndex].dailyPlans[dayIndex].isCompleted = completed
        self.currentUserProgram = userProgram
        programUpdated.send()
        
        // Instead of updating a single field, update the entire document so it always remains complete.
        let docRef = db.collection("userRunningPrograms").document(userProgram.id.uuidString)
        
        let fullDict = dictionaryFrom(userProgram: userProgram)
        print("MARK COMPLETE: Overwriting user instance doc '\(userProgram.id.uuidString)' with full data: \(fullDict)")
        do {
            try await docRef.setData(fullDict, merge: false)
            print("MARK COMPLETE: User instance updated successfully.")
        } catch let updateError {
            print("MARK COMPLETE ERROR: User instance update failed: \(updateError.localizedDescription)")
        }
    }
    
    



}

// MARK: - Helper Functions

func generateStableDocumentId(for programTitle: String) -> String {
    let lowercased = programTitle.lowercased()
    let allowedChars = CharacterSet.alphanumerics.union(.whitespaces)
    let sanitized = lowercased.components(separatedBy: allowedChars.inverted).joined()
    let hyphenated = sanitized.replacingOccurrences(of: " ", with: "-")
    let maxLength = 100
    let truncated = String(hyphenated.prefix(maxLength))
    return truncated.isEmpty ? UUID().uuidString : truncated
}

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
                "completed": day.isCompleted
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

func dictionaryFrom(userProgram: UserRunningProgram) -> [String: Any] {
    let weeklyPlanData = userProgram.weeklyPlan.map { week -> [String: Any] in
        let dailyPlansData = week.dailyPlans.map { day -> [String: Any] in
            return [
                "day": day.day,
                "dailyDate": day.dailyDate != nil ? Timestamp(date: day.dailyDate!) : NSNull(),
                "dailyDistance": day.dailyDistance,
                "dailyRunType": day.dailyRunType ?? "",
                "dailyEstimatedDuration": day.dailyEstimatedDuration ?? "",
                "dailyWorkoutDetails": day.dailyWorkoutDetails ?? [],
                "completed": day.isCompleted
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
    
    let calculatedTotalDistance = userProgram.weeklyPlan.reduce(0) { $0 + $1.weeklyTotalDistance }
    
    return [
        "id": userProgram.id.uuidString,
        "templateId": userProgram.templateId,
        "title": userProgram.title,
        "raceName": userProgram.raceName ?? "",
        "subtitle": userProgram.subtitle,
        // Convert dates to Timestamps
        "finishDate": Timestamp(date: userProgram.finishDate),
        "imageUrl": userProgram.imageUrl,
        "totalDistance": calculatedTotalDistance,
        "planOverview": userProgram.planOverview,
        "experienceLevel": userProgram.experienceLevel,
        "weeklyPlan": weeklyPlanData,
        "username": userProgram.username,
        "startDate": Timestamp(date: userProgram.startDate),
        "overallCompletion": userProgram.overallCompletion,
        "userProgramActive": userProgram.userProgramActive,
        "userProgramCompleted": userProgram.userProgramCompleted,
        // NEW: Persist the target race time
        "targetTimeSeconds": userProgram.targetTimeSeconds
    ]
}







// ONLY CALL THIS ONCE EVER AND DONT MAKE IT CALLABLE IN THE APP
@MainActor
func seedTemplateIfNeeded(_ template: NewRunningProgram) async throws {
    let db = Firestore.firestore()
    
    let stableId = generateStableDocumentId(for: template.title)
    let templateRef = db.collection("runningProgramTemplates").document(stableId)
    
    // Check if the template already exists.
    let document = try await templateRef.getDocument()
    if document.exists {
        print("Template '\(template.title)' already exists.")
    } else {
        let data = dictionaryFrom(program: template)
        try await templateRef.setData(data, merge: false)
        print("Template '\(template.title)' created successfully in runningProgramTemplates.")
    }
}



func mergeWeeklyPlans(template: [WeeklyPlan], user: [WeeklyPlan]?) -> [WeeklyPlan] {
    // If there's no user progress, return the template as is.
    guard let user = user else { return template }
    
    // Assume same ordering and count; if not, you might need to merge by unique identifiers.
    var merged = template
    
    // Loop through weeks and days to update the completed flag.
    for weekIndex in 0..<min(template.count, user.count) {
        for dayIndex in 0..<min(template[weekIndex].dailyPlans.count, user[weekIndex].dailyPlans.count) {
            // Use the user instance value
            merged[weekIndex].dailyPlans[dayIndex].isCompleted = user[weekIndex].dailyPlans[dayIndex].isCompleted
        }
    }
    return merged
}

func dictionaryFrom(day: DailyPlan) -> [String: Any] {
    return [
        "day": day.day,
        "dailyDate": day.dailyDate != nil ? Timestamp(date: day.dailyDate!) : NSNull(),
        "dailyDistance": day.dailyDistance,
        "dailyRunType": day.dailyRunType ?? "",
        "dailyEstimatedDuration": day.dailyEstimatedDuration ?? "",
        "dailyWorkoutDetails": day.dailyWorkoutDetails ?? [],
        "completed": day.isCompleted
    ]
}


// new 2 might have to remove
func dictionaryFrom(week: WeeklyPlan) -> [String: Any] {
    let dailyPlansData = week.dailyPlans.map { dictionaryFrom(day: $0) }
    return [
        "weekNumber": week.weekNumber,
        "weekTitle": week.weekTitle,
        "weeklyTotalWorkouts": week.weeklyTotalWorkouts,
        "weeklyTotalDistance": week.weeklyTotalDistance,
        "dailyPlans": dailyPlansData,
        "weeklyDescription": week.weeklyDescription
    ]
}

extension NewRunningProgramViewModel {
    /// Returns true if today's run (if found) is completed.
    /// If no daily plan for today is found, it assumes the run is complete.
    var currentDailyRunIsCompleted: Bool {
        guard let userProgram = currentUserProgram else { return true }
        // Look for a daily plan scheduled for today.
        for week in userProgram.weeklyPlan {
            for day in week.dailyPlans {
                if let date = day.dailyDate, Calendar.current.isDateInToday(date) {
                    return day.isCompleted
                }
            }
        }
        // If none is found, assume today's run is not yet completed.
        return false
    }

    
    /// Optionally, if you want to get today's target distance (for use in your RunInProgressCardView),
    /// you could add something like:
    var currentDailyTargetDistance: Double {
            guard let userProgram = currentUserProgram else { return 0 }
            
            // Get today's weekday name from the current calendar.
            let todayWeekday = Calendar.current.component(.weekday, from: Date())
            let weekdaySymbols = Calendar.current.weekdaySymbols // ["Sunday", "Monday", "Tuesday", ...]
            let todayName = weekdaySymbols[todayWeekday - 1] // e.g. "Tuesday"
            
            // Iterate through the weekly plans.
            for week in userProgram.weeklyPlan {
                for day in week.dailyPlans {
                    // First, if a dailyDate is present, check if it's today.
                    if let date = day.dailyDate, Calendar.current.isDateInToday(date) {
                        return day.dailyDistance
                    }
                    // Fallback: if dailyDate is not set, compare the day name.
                    if day.day.caseInsensitiveCompare(todayName) == .orderedSame {
                        return day.dailyDistance
                    }
                }
            }
            return 0
        }
    }

extension NewRunningProgramViewModel {
    func getTodaysDailyPlan() -> DailyPlan? {
        // If an override is provided, return that.
        if let override = todaysDailyPlanOverride {
            return override
        }
        // Otherwise, use the default logic.
        guard let userProgram = currentUserProgram else { return nil }
        for week in userProgram.weeklyPlan {
            for day in week.dailyPlans {
                if let date = day.dailyDate, Calendar.current.isDateInToday(date) {
                    return day
                }
            }
        }
        return nil
    }
}


extension NewRunningProgramViewModel {
    /// Returns the indices (week and day) for the daily plan corresponding to today.
    func getTodaysDailyPlanIndices() -> (weekIndex: Int, dayIndex: Int)? {
        guard let userProgram = currentUserProgram else { return nil }
        let today = Date()
        let calendar = Calendar.current
        for (weekIndex, week) in userProgram.weeklyPlan.enumerated() {
            for (dayIndex, day) in week.dailyPlans.enumerated() {
                if let date = day.dailyDate, calendar.isDate(date, inSameDayAs: today) {
                    return (weekIndex, dayIndex)
                }
                // Fallback: if the dailyDate isn’t set, you could also compare by day name.
                let weekdaySymbols = calendar.weekdaySymbols
                let todayName = weekdaySymbols[calendar.component(.weekday, from: today) - 1]
                if day.dailyDate == nil && day.day.caseInsensitiveCompare(todayName) == .orderedSame {
                    return (weekIndex, dayIndex)
                }
            }
        }
        return nil
    }
}
