//
//  NewRunningProgramViewModel.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import Foundation
import FirebaseFirestore
import Combine // Import Combine for PassthroughSubject

class NewRunningProgramViewModel: ObservableObject {
    
    @Published var currentProgram: NewRunningProgram?
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    // Store the STABLE document ID for the currently loaded program
    // In NewRunningProgramViewModel.swift
    @Published private(set) var currentStableDocumentId: String? = nil // Change 'private' to 'private(set)'
    private let db = Firestore.firestore()
    
    // Optional: To notify views when a program is updated (e.g., completion status)
    let programUpdated = PassthroughSubject<Void, Never>()
    
    // --- NEW: Load a specific program ---
    @MainActor // Ensure updates happen on the main thread
    func loadProgram(titled programTitle: String) async {
        guard !programTitle.isEmpty else {
            print("PROGRAM LOAD ERROR: Program title is empty.")
            self.currentProgram = nil
            self.currentStableDocumentId = nil
            return
        }
        
        isLoading = true
        error = nil
        self.currentProgram = nil // Clear previous program while loading
        let stableId = generateStableDocumentId(for: programTitle)
        self.currentStableDocumentId = stableId // Store the ID we're using
        
        print("PROGRAM LOAD: Attempting to load program with stable ID: \(stableId)")
        
        let docRef = db.collection("runningPrograms").document(stableId)
        
        do {
            let document = try await docRef.getDocument()
            if document.exists, let data = document.data() {
                // --- You need a way to decode Firestore data back into your NewRunningProgram struct ---
                // This requires NewRunningProgram and its nested types to be Decodable
                // or you need a manual initializer like the Goal one.
                // Assuming you have an initializer or decoding logic:
                self.currentProgram = NewRunningProgram(from: data) // Replace with your actual decoding/init
                // ---------------------------------------------------------------
                print("PROGRAM LOAD: Successfully loaded '\(programTitle)'")
            } else {
                print("PROGRAM LOAD WARNING: No program found with title '\(programTitle)' (ID: \(stableId)).")
                // Optionally: Handle creation of a default program if it doesn't exist?
                self.error = NSError(domain: "AppError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Running program not found."])
            }
        } catch let fetchError {
            print("PROGRAM LOAD ERROR: Failed to fetch program '\(programTitle)': \(fetchError.localizedDescription)")
            self.error = fetchError
        }
        isLoading = false
    }
    
    
    // --- MODIFIED: Save or Create (Use Stable ID) ---
    // This should primarily be used when CREATING a new program or making MAJOR edits.
    // For simple updates like completion, use markDailyRunCompleted.
    @MainActor
    func saveNewRunningProgram(_ program: NewRunningProgram) async {
        guard !program.title.isEmpty else {
            print("PROGRAM SAVE ERROR: Program title cannot be empty.")
            return
        }
        isLoading = true
        error = nil
        let stableId = generateStableDocumentId(for: program.title)
        let data = dictionaryFrom(program: program) // Use your existing conversion function
        
        print("PROGRAM SAVE: Saving program '\(program.title)' with stable ID: \(stableId)")
        
        let docRef = db.collection("runningPrograms").document(stableId)
        
        do {
            // Use setData with merge:false initially, or decide on update strategy
            // If you want it to *always* overwrite or create, use setData without merge.
            // If you want it to create or update existing fields, use setData with merge:true
            try await docRef.setData(data, merge: true)
            self.currentProgram = program // Update local state
            self.currentStableDocumentId = stableId // Store the ID
            print("PROGRAM SAVE: Program '\(program.title)' saved successfully!")
            programUpdated.send() // Notify listeners
        } catch let saveError {
            print("PROGRAM SAVE ERROR: Failed to save program '\(program.title)': \(saveError.localizedDescription)")
            self.error = saveError
        }
        isLoading = false
    }
    
    
    // --- REVISED: Mark Daily Run Completed (Efficient Update) ---
    @MainActor
    func markDailyRunCompleted(weekIndex: Int, dayIndex: Int, completed: Bool) async {
        // Guard against trying to update a program that isn't loaded
        guard let stableId = currentStableDocumentId, var program = currentProgram else {
            print("MARK COMPLETE ERROR: No program loaded to update.")
            return
        }
        // Validate indices
        guard program.weeklyPlan.indices.contains(weekIndex),
              program.weeklyPlan[weekIndex].dailyPlans.indices.contains(dayIndex) else {
            print("MARK COMPLETE ERROR: Invalid week (\(weekIndex)) or day (\(dayIndex)) index.")
            return
        }
        
        // Update local state FIRST for immediate UI feedback
        program.weeklyPlan[weekIndex].dailyPlans[dayIndex].isCompleted = completed
        self.currentProgram = program // Assign the modified program back to the @Published var
        programUpdated.send() // Notify UI immediately
        
        // --- Update ONLY the specific field in Firestore ---
        let fieldPath = "weeklyPlan.\(weekIndex).dailyPlans.\(dayIndex).completed"
        let docRef = db.collection("runningPrograms").document(stableId)
        
        print("MARK COMPLETE: Updating Firestore doc '\(stableId)' path '\(fieldPath)' to \(completed)")
        
        do {
            // Use updateData for targeted field update
            try await docRef.updateData([fieldPath: completed])
            print("MARK COMPLETE: Firestore updated successfully.")
        } catch let updateError {
            print("MARK COMPLETE ERROR: Firestore update failed: \(updateError.localizedDescription)")
            // Optionally: Revert local state change on error
            // program.weeklyPlan[weekIndex].dailyPlans[dayIndex].isCompleted = !completed
            // self.currentProgram = program
            // self.error = updateError
            // programUpdated.send() // Notify UI of reversion
        }
    }
}

// Helper function to generate a custom document ID based on date and time
/// Generates a Firestore-safe document ID from a program title.
/// (e.g., "My 10k Plan!" -> "my-10k-plan-")
func generateStableDocumentId(for programTitle: String) -> String {
    let lowercased = programTitle.lowercased()
    // Remove disallowed characters and replace spaces with hyphens
    let allowedChars = CharacterSet.alphanumerics.union(.whitespaces)
    let sanitized = lowercased.components(separatedBy: allowedChars.inverted).joined()
    let hyphenated = sanitized.replacingOccurrences(of: " ", with: "-")
    // Truncate if too long (Firestore IDs have limits, though usually generous)
    let maxLength = 100 // Example max length
    let truncated = String(hyphenated.prefix(maxLength))
    // Handle empty string case
    return truncated.isEmpty ? UUID().uuidString : truncated // Use UUID if title sanitizes to empty
}

// You can now REMOVE the old generateDocumentId() function that used DateFormatter.

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
