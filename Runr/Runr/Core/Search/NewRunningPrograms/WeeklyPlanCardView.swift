//
//  WeeklyPlanCardView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct WeeklyPlanCardView: View {
    let plan: WeeklyPlan
    let weekIndex: Int // Index of the week this card represents
    @EnvironmentObject var viewModel: NewRunningProgramViewModel

    // Helper: Determine if the given week is the current week based on the program's start date.
    // Returns true if this card’s weekIndex matches today’s scheduled week.
    private func isCurrentWeek() -> Bool {
        guard let todayWeek = viewModel.getTodaysDailyPlanIndices()?.weekIndex else {
            return false
        }
        return todayWeek == weekIndex
    }

    
    // Helper: Determine if a given daily plan is scheduled for today and is in the current week.
    private func isTodayInCurrentWeek(_ dayPlan: DailyPlan) -> Bool {
        // Only return true if this card represents the current week.
        guard isCurrentWeek() else { return false }
        let today = Date()
        let calendar = Calendar.current
        if let date = dayPlan.dailyDate {
            return calendar.isDate(date, inSameDayAs: today)
        } else {
            let todayWeekday = calendar.weekdaySymbols[calendar.component(.weekday, from: today) - 1]
            return dayPlan.day.caseInsensitiveCompare(todayWeekday) == .orderedSame
        }
    }
    
    var body: some View {
        NavigationLink(destination: WeeklyPlanView(plan: plan, weekIndex: weekIndex, viewModel: _viewModel)) {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(plan.weekTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.blue)
                
                // Summary
                HStack {
                    Label("Workouts: \(plan.weeklyTotalWorkouts)", systemImage: "figure.run")
                    Spacer()
                    Label("Total: \(plan.weeklyTotalDistance, specifier: "%.1f") km", systemImage: "ruler")
                }
                
                Divider().padding(.vertical, 4)
                
                // Daily Breakdown: For each daily plan, highlight only if the day is scheduled for today in the current week.
                // Daily Breakdown: For each daily plan, highlight only if the day is scheduled for today in the current week.
                ForEach(plan.dailyPlans, id: \.id) { dayPlan in
                    HStack {
                        // Display tick icon and day label in one line without wrapping.
                        HStack(spacing: 4) {
                            if dayPlan.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                            Text(dayPlan.day + ":")
                                .font(.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(width: 80, alignment: .leading) // Increased width from 70 to 80
                                        
                        Text(dayPlan.dailyDistance > 0 ? "\(dayPlan.dailyDistance, specifier: "%.1f") km" : "Rest")
                            .font(.caption)
                            .foregroundColor(dayPlan.dailyDistance > 0 ? .primary : .secondary)
                        Spacer()
                    }
                    .padding(4)
                    // Highlight if this is the current day's run and not completed; otherwise, use green if completed.
                    .background(isTodayInCurrentWeek(dayPlan) && !dayPlan.isCompleted ? Color.blue.opacity(0.2) : (dayPlan.isCompleted ? Color.green.opacity(0.3) : Color.clear))
                    .cornerRadius(4)
                }

            }
            .padding()
            // Overall card styling.
            .background(plan.isCompleted ? Color.green.opacity(0.2) : Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(plan.isCompleted ? Color.green : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WeeklyPlanCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide sample data as needed. Assume sampleDailyPlans is defined.
        let samplePlan = WeeklyPlan(
            weekNumber: 1,
            weekTitle: "Sample Week",
            weeklyTotalWorkouts: 4,
            weeklyTotalDistance: 20,
            dailyPlans: sampleDailyPlans,
            weeklyDescription: "A sample week"
        )
        let previewViewModel = NewRunningProgramViewModel()
        WeeklyPlanCardView(plan: samplePlan, weekIndex: 0)
            .environmentObject(previewViewModel)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
