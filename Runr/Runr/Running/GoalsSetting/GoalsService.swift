//
//  GoalsService.swift
//  Runr
//
//  Created by Noah Moran on 3/4/2025.
//

import FirebaseFirestore
import FirebaseAuth
import Foundation // For Calendar and Date calculations

// MARK: - Goal Data Handling Service
class GoalsService {
    static let shared = GoalsService()
    private let db = Firestore.firestore()

    private init() {} // Singleton pattern

    // Helper to get user ID
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    // --- MODIFIED: Upload User Goals ---
    func uploadUserGoals(goals: [Goal]) async {
        guard let userId = currentUserId else {
            print("GOALS ERROR: No user logged in.")
            return
        }

        let goalsCollection = db.collection("users").document(userId).collection("goals")

        for var goal in goals { // Make goal mutable if needed
            // --- Parse targetRaw to get targetValue and targetUnit ---
            // (Implement robust parsing based on how users input targets, e.g., "11 km", "30 min")
            let parsed = parseTarget(goal.targetRaw) // You need to implement parseTarget
            goal.targetValue = parsed.value
            goal.targetUnit = parsed.unit
            goal.period = determinePeriod(from: goal.title) // You need to implement determinePeriod

            // Prepare data for Firestore
            let goalData: [String: Any] = [
                "title": goal.title,
                "category": goal.category,
                "targetRaw": goal.targetRaw, // Store original string
                "targetValue": goal.targetValue,
                "targetUnit": goal.targetUnit,
                "period": goal.period,
                "currentProgress": 0.0, // Start progress at 0
                "isCompleted": false,
                "lastResetDate": NSNull(), // Use NSNull for initial non-set date
                "timestamp": FieldValue.serverTimestamp() // Use server timestamp
            ]

            do {
                // Use goal title or a generated ID for the document ID - careful with duplicates/updates
                // Using title might be okay if user can't create duplicate titles
                let docRef = goalsCollection.document(goal.title.replacingOccurrences(of: "/", with: "-")) // Simple ID from title
                try await docRef.setData(goalData, merge: true) // Use merge to allow updates
                print("Goal '\(goal.title)' uploaded/updated successfully.")
            } catch {
                print("GOALS ERROR: Error uploading goal '\(goal.title)': \(error.localizedDescription)")
            }
        }
    }

    // --- MODIFIED: Fetch User Goals ---
    func fetchUserGoals() async -> [Goal] {
        guard let userId = currentUserId else {
            print("GOALS ERROR: No user logged in for fetching.")
            return []
        }

        let goalsCollection = db.collection("users").document(userId).collection("goals")

        do {
            let snapshot = try await goalsCollection.getDocuments()
            let goals: [Goal] = snapshot.documents.compactMap { document in
                // Use the initializer that takes Firestore data
                return Goal(id: document.documentID, data: document.data())
            }
            print("Fetched \(goals.count) goals.")
            return goals
        } catch {
            print("GOALS ERROR: Error fetching goals: \(error.localizedDescription)")
            return []
        }
    }

    // --- NEW: Update Progress After a Run ---
    func updateGoalsProgress(runDistance: Double, runDuration: TimeInterval, runDate: Date) async {
         guard let userId = currentUserId else { return }
         guard runDistance > 0 || runDuration > 0 else { return } // Ignore zero runs

         print("GOALS UPDATE: Starting for run on \(runDate). Dist: \(runDistance), Dur: \(runDuration)")

         let goalsCollection = db.collection("users").document(userId).collection("goals")
         let fetchedGoals = await fetchUserGoals() // Fetch current state of all goals

         let calendar = Calendar.current
         let now = Date() // Use consistent 'now' for checks

         for var goal in fetchedGoals { // Make mutable to update progress locally
             var needsUpdate = false
             var needsReset = false
             var newProgress = goal.currentProgress
             let newLastResetDate = goal.lastResetDate // Start with existing reset date

             // --- Check if progress needs reset (for periodic goals) ---
             if goal.period == "monthly" {
                 if let lastReset = goal.lastResetDate {
                     // If last reset was before the start of the current month
                     if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
                         needsReset = true
                     }
                 } else {
                      // If never reset before, and the run is happening now, "reset" for this month
                      needsReset = true
                 }
             } else if goal.period == "weekly" {
                 if let lastReset = goal.lastResetDate {
                      // If last reset was before the start of the current week (assuming week starts Sunday/Monday based on locale)
                      if !calendar.isDate(lastReset, equalTo: now, toGranularity: .weekOfYear) {
                          needsReset = true
                      }
                  } else {
                      needsReset = true
                  }
             }
             // Add checks for other periods (daily, etc.) if needed

             if needsReset {
                  print("GOALS UPDATE: Resetting progress for goal '\(goal.title)'")
                  newProgress = 0.0
                  goal.isCompleted = false // Reset completion status too
                  // Set new reset date to the beginning of the current period
                  if goal.period == "monthly" {
                       goal.lastResetDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
                  } else if goal.period == "weekly" {
                       goal.lastResetDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
                  }
                   needsUpdate = true
              } else {
                   // If no reset, keep existing reset date
                   goal.lastResetDate = newLastResetDate // Explicitly assign back
              }


             // --- Accumulate Progress if run is relevant to current period ---
             var isRunRelevant = false
             switch goal.period {
                 case "monthly":
                     isRunRelevant = calendar.isDate(runDate, equalTo: now, toGranularity: .month)
                 case "weekly":
                     isRunRelevant = calendar.isDate(runDate, equalTo: now, toGranularity: .weekOfYear)
                 case "allTime", "singleRun": // 'singleRun' might need special handling based on title/category
                     isRunRelevant = true // Always relevant unless specific conditions apply
                 default:
                     isRunRelevant = false
             }

             if isRunRelevant && !goal.isCompleted { // Only add progress if relevant and not already complete for the period
                  print("GOALS UPDATE: Run is relevant for goal '\(goal.title)'")
                  var progressToAdd: Double = 0.0

                  // Add progress based on goal category/unit
                  if goal.category == "Distance" && goal.targetUnit == "km" {
                      progressToAdd = runDistance / 1000.0 // Convert run distance (meters) to km
                  } else if goal.category == "Distance" && goal.targetUnit == "m" {
                       progressToAdd = runDistance // Use run distance directly if goal unit is meters
                   }else if goal.category == "Time" && goal.targetUnit == "minutes" {
                       progressToAdd = runDuration / 60.0 // Convert run duration (seconds) to minutes
                   } else if goal.category == "Time" && goal.targetUnit == "hours" {
                        progressToAdd = runDuration / 3600.0
                    }
                   // Add more conditions for pace, frequency, longest run, etc.
                   // For 'Longest Single Run' type goals:
                   // if goal.title == "Longest Single Run" { newProgress = max(newProgress, runDistance / 1000.0) }

                   if progressToAdd > 0 {
                       newProgress += progressToAdd
                       needsUpdate = true
                        print("GOALS UPDATE: Added \(progressToAdd) \(goal.targetUnit) to '\(goal.title)'. New progress: \(newProgress)")
                   }

                  // --- Check for Completion ---
                  if newProgress >= goal.targetValue {
                      print("GOALS UPDATE: Goal '\(goal.title)' COMPLETED!")
                      goal.isCompleted = true
                       // Optional: Clamp progress to target? Or allow exceeding?
                       // newProgress = goal.targetValue
                      needsUpdate = true
                  }
             } else if !isRunRelevant {
                 print("GOALS UPDATE: Run is NOT relevant for current period of goal '\(goal.title)' (Period: \(goal.period))")
             } else if goal.isCompleted {
                  print("GOALS UPDATE: Goal '\(goal.title)' is already completed for this period.")
              }

             // --- Update Firestore if necessary ---
             if needsUpdate {
                  goal.currentProgress = newProgress // Update the mutable goal struct

                  let goalDocRef = goalsCollection.document(goal.id) // Use the fetched ID
                  var updateData: [String: Any] = [
                      "currentProgress": goal.currentProgress,
                      "isCompleted": goal.isCompleted
                  ]
                  // Only include lastResetDate if it changed
                  if let newDate = goal.lastResetDate, newDate != newLastResetDate {
                       updateData["lastResetDate"] = Timestamp(date: newDate)
                   } else if goal.lastResetDate == nil && newLastResetDate != nil {
                        // Handle case where it was nil and becomes non-nil (should be covered by needsReset logic)
                        updateData["lastResetDate"] = Timestamp(date: Date()) // Fallback, adjust if needed
                   }


                  do {
                      try await goalDocRef.updateData(updateData)
                      print("GOALS UPDATE: Firestore updated for goal '\(goal.title)'.")
                  } catch {
                      print("GOALS ERROR: Failed to update goal '\(goal.title)' in Firestore: \(error)")
                  }
             }
         }
         print("GOALS UPDATE: Finished processing goals.")
     }

     // --- Helper Functions (Implement These) ---
     private func parseTarget(_ targetString: String) -> (value: Double, unit: String) {
         // Example basic parsing: assumes "VALUE UNIT" format
         let components = targetString.lowercased().split(separator: " ")
         guard components.count == 2, let value = Double(components[0]) else {
             return (0.0, "") // Invalid format
         }
         let unit = String(components[1])
         // Add more robust parsing if needed (e.g., handle "1:30 hr")
         return (value, unit)
     }

     private func determinePeriod(from title: String) -> String {
         let lowerTitle = title.lowercased()
         if lowerTitle.contains("monthly") { return "monthly" }
         if lowerTitle.contains("weekly") { return "weekly" }
         if lowerTitle.contains("daily") { return "daily" }
         if lowerTitle.contains("single run") { return "singleRun" } // Example
         // Add more rules or default
         return "allTime"
     }
}
