//
//  UserRunningProgram.swift
//  Runr
//
//  Created by Noah Moran on 8/4/2025.
//

import Foundation
import FirebaseFirestore

struct UserRunningProgram: Identifiable {
    let id: UUID
    let templateId: String    // Reference to the original template document
    
    
    // Template Data (copied from the template)
    let title: String
    let raceName: String?
    let subtitle: String
    let finishDate: Date
    let imageUrl: String
    let totalDistance: Int
    let planOverview: String
    let experienceLevel: String
    var weeklyPlan: [WeeklyPlan]   // Contains DailyPlan objects with their own 'completed' flags
    
    // User-Specific Fields
    let username: String           // Username of the user who started the program
    let startDate: Date            // When the user started the program
    var overallCompletion: Int     // e.g. 0 initially, then updated as the user progresses
    var userProgramActive: Bool    // Indicates if the program is still active
    var userProgramCompleted: Bool // Indicates if the entire program is completed
    
    // NEW: Add targetTimeSeconds to store the user's desired race time.
    var targetTimeSeconds: Double

    // Initializer that creates a new user instance from a template.
    init(from template: NewRunningProgram, username: String) {
        self.id = UUID() // New unique ID for this user instance
        self.templateId = generateStableDocumentId(for: template.title)
        
        // Copy all template fields.
        self.title = template.title
        self.raceName = template.raceName
        self.subtitle = template.subtitle
        self.finishDate = template.finishDate
        self.imageUrl = template.imageUrl
        self.totalDistance = template.totalDistance
        self.planOverview = template.planOverview
        self.experienceLevel = template.experienceLevel
        self.weeklyPlan = template.weeklyPlan
        
        // User-specific fields.
        self.username = username
        self.startDate = Date()
        self.overallCompletion = 0
        self.userProgramActive = true
        self.userProgramCompleted = false
        
        // Initialize with a default target time (e.g., 10800 seconds)
        // which can later be updated by the user.
        self.targetTimeSeconds = 10800
    }
}
