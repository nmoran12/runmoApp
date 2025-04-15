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

    init(from template: NewRunningProgram, username: String) {
        // 1) Create a local variable for the user's start date.
        let startDate = Date()
        // 2) Compute the weekly plan with actual dates.
        let assignedPlan = assignDatesToWeeklyPlan(template.weeklyPlan, startingAt: startDate)
        
        // 3) Now initialize all stored properties.
        self.id = UUID()
        self.templateId = generateStableDocumentId(for: template.title)
        self.title = template.title
        self.raceName = template.raceName
        self.subtitle = template.subtitle
        self.finishDate = template.finishDate
        self.imageUrl = template.imageUrl
        self.totalDistance = template.totalDistance
        self.planOverview = template.planOverview
        self.experienceLevel = template.experienceLevel
        
        // 4) Assign the newly computed weekly plan.
        self.weeklyPlan = assignedPlan
        
        // 5) Finally, set user-specific fields.
        self.username = username
        self.startDate = startDate
        self.overallCompletion = 0
        self.userProgramActive = true
        self.userProgramCompleted = false
        self.targetTimeSeconds = 10800
    }




}

/// Given a day name (e.g., "Monday"), return the weekday number according to the current calendar.
/// In the default Gregorian calendar (with en_US_POSIX locale), Sunday=1, Monday=2, …, Saturday=7.
func parseDayName(_ dayName: String) -> Int? {
    let name = dayName.lowercased()
    switch name {
    case "sunday":    return 1
    case "monday":    return 2
    case "tuesday":   return 3
    case "wednesday": return 4
    case "thursday":  return 5
    case "friday":    return 6
    case "saturday":  return 7
    default:
        return nil
    }
}

/// Returns a DailyPlan but with its `dailyDate` updated to `newDate`
func dailyPlanWithAssignedDate(_ plan: DailyPlan, _ newDate: Date) -> DailyPlan {
    return DailyPlan(
        day: plan.day,
        date: newDate,
        distance: plan.dailyDistance,
        runType: plan.dailyRunType,
        estimatedDuration: plan.dailyEstimatedDuration,
        workoutDetails: plan.dailyWorkoutDetails,
        isCompleted: plan.isCompleted
    )
}

/// Updates the weekly plan by aligning the day labels with actual calendar dates.
/// For the first week, only the runs on or after the user's start day are used.
/// Subsequent weeks are assigned full weeks (Monday–Sunday).
func assignDatesToWeeklyPlan(_ weeks: [WeeklyPlan], startingAt startDate: Date) -> [WeeklyPlan] {
    var newWeeks: [WeeklyPlan] = []
    let calendar = Calendar.current

    // Compute the Monday of the current week.
    // (Here we assume Monday is the first day of the training week.)
    guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)) else {
        // Fallback: just return the original weeks.
        return weeks
    }
    let userStartWeekday = calendar.component(.weekday, from: startDate)
    
    // -- Process the FIRST WEEK (partial week if user started mid-week) --
    if let firstTemplateWeek = weeks.first {
        var newDailyPlans: [DailyPlan] = []
        
        // Iterate through the daily plans in the template's first week.
        for daily in firstTemplateWeek.dailyPlans {
            // Convert the day label (e.g., "Monday") to a weekday integer.
            if let planWeekday = parseDayName(daily.day) {
                // Only assign a run if its weekday is equal to or after the user's start weekday.
                if planWeekday >= userStartWeekday {
                    // Compute the date for that day in the current week.
                    // currentWeekStart is Monday (weekday = 2), so the offset is:
                    let offset = planWeekday - 2  // For Monday (2) this gives 0, Tuesday (3) gives 1, etc.
                    if let assignedDate = calendar.date(byAdding: .day, value: offset, to: currentWeekStart) {
                        newDailyPlans.append(dailyPlanWithAssignedDate(daily, assignedDate))
                    }
                }
            }
        }
        // Only add the first week if there are any runs scheduled for it.
        if !newDailyPlans.isEmpty {
            let newFirstWeek = WeeklyPlan(
                weekNumber: 1,
                weekTitle: firstTemplateWeek.weekTitle,
                weeklyTotalWorkouts: firstTemplateWeek.weeklyTotalWorkouts,
                weeklyTotalDistance: firstTemplateWeek.weeklyTotalDistance,
                dailyPlans: newDailyPlans,
                weeklyDescription: firstTemplateWeek.weeklyDescription
            )
            newWeeks.append(newFirstWeek)
        }
    }
    
    // -- Process subsequent weeks from the template (full weeks) --
    // For week index 1 and onward in the template (if any).
    // For each subsequent week, calculate the Monday of that week.
    for (index, templateWeek) in weeks.enumerated() {
        if index == 0 { continue }  // Already did the first week.
        // Compute the start of this week by adding (index * 7) days to the Monday of the current week.
        if let weekStartDate = calendar.date(byAdding: .day, value: index * 7, to: currentWeekStart) {
            var newDailyPlans: [DailyPlan] = []
            for daily in templateWeek.dailyPlans {
                if let planWeekday = parseDayName(daily.day) {
                    // Compute the offset from Monday in that week.
                    let offset = planWeekday - 2
                    if let assignedDate = calendar.date(byAdding: .day, value: offset, to: weekStartDate) {
                        newDailyPlans.append(dailyPlanWithAssignedDate(daily, assignedDate))
                    }
                }
            }
            let newWeek = WeeklyPlan(
                weekNumber: index + 1,
                weekTitle: templateWeek.weekTitle,
                weeklyTotalWorkouts: templateWeek.weeklyTotalWorkouts,
                weeklyTotalDistance: templateWeek.weeklyTotalDistance,
                dailyPlans: newDailyPlans,
                weeklyDescription: templateWeek.weeklyDescription
            )
            newWeeks.append(newWeek)
        }
    }
    
    return newWeeks
}

extension UserRunningProgram {
    init(from template: NewRunningProgram, username: String, existingId: UUID?) {
        let startDate = Date()
        let assignedPlan = assignDatesToWeeklyPlan(template.weeklyPlan, startingAt: startDate)
        
        // If an existing ID is provided, re-use it; otherwise, generate a new one.
        self.id = existingId ?? UUID()
        self.templateId = generateStableDocumentId(for: template.title)
        self.title = template.title
        self.raceName = template.raceName
        self.subtitle = template.subtitle
        self.finishDate = template.finishDate
        self.imageUrl = template.imageUrl
        self.totalDistance = template.totalDistance
        self.planOverview = template.planOverview
        self.experienceLevel = template.experienceLevel
        self.weeklyPlan = assignedPlan
        
        self.username = username
        self.startDate = startDate
        self.overallCompletion = 0
        self.userProgramActive = true
        self.userProgramCompleted = false
        self.targetTimeSeconds = 10800
    }
}
