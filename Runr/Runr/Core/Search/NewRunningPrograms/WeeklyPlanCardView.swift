//
//  WeeklyPlanCardView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct WeeklyPlanCardView: View {
    let plan: WeeklyPlan
    let weekIndex: Int // <-- Add week index
    @ObservedObject var viewModel: NewRunningProgramViewModel // <-- Add view model

    var body: some View {
        // Pass weekIndex and viewModel to the destination
        NavigationLink(destination: WeeklyPlanView(plan: plan, weekIndex: weekIndex, viewModel: viewModel)) {
            // ... Keep the existing content of the card (VStack with Text, Labels, HStacks) ...
            VStack(alignment: .leading, spacing: 12) {
               // Title
                Text(plan.weekTitle)
                   .font(.title2)
                   .fontWeight(.bold)
                   .foregroundColor(Color.blue)

               // Summary
                HStack {
                   Label("Workouts: \(plan.weeklyTotalWorkouts)", systemImage: "figure.run")
                       // ... modifiers
                   Spacer()
                   Label("Total: \(plan.weeklyTotalDistance, specifier: "%.1f") km", systemImage: "ruler")
                       // ... modifiers
                }

               Divider().padding(.vertical, 4)

               // Daily Breakdown (Keep your existing layout for this)
               // Example structure:
                ForEach(Array(plan.dailyPlans.prefix(3).enumerated()), id: \.element.id) { index, dayPlan in
                     HStack {
                         Text(dayPlan.day + ":") // Day name
                             .font(.caption)
                             .frame(width: 70, alignment: .leading)
                         Text(dayPlan.dailyDistance > 0 ? "\(dayPlan.dailyDistance, specifier: "%.1f") km" : "Rest")
                             .font(.caption)
                             .foregroundColor(dayPlan.dailyDistance > 0 ? .primary : .secondary)
                         Spacer()
                     }
                 }
                if plan.dailyPlans.count > 3 {
                    Text("...and more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground)) // Use adaptive background
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Slightly adjusted shadow
            .overlay(
                 RoundedRectangle(cornerRadius: 16)
                     .stroke(Color.gray.opacity(0.2), lineWidth: 1)
             )
        }
         .buttonStyle(PlainButtonStyle()) // Make the whole card tappable without button styling
    }
    // Removed distanceIndicator as it might be complex here, simplified daily display
}

struct WeeklyPlanCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Create necessary sample data
        // --- Use the globally defined sampleDailyPlans ---
        let samplePlan = WeeklyPlan(
            weekNumber: 1,
            weekTitle: "Sample Title in WeeklyPlanCardView",
            weeklyTotalWorkouts: sampleDailyPlans.filter { $0.dailyDistance > 0 }.count,
            weeklyTotalDistance: sampleDailyPlans.reduce(0) { $0 + $1.dailyDistance },
            dailyPlans: sampleDailyPlans, // <-- Use global constant here
            weeklyDescription: "preview weekly description"
        )
        let previewViewModel = NewRunningProgramViewModel()

        // --- REMOVE the local 'let sampleDailyPlans = [...]' block ---

        WeeklyPlanCardView(
            plan: samplePlan,
            weekIndex: 0, // Sample index
            viewModel: previewViewModel // Dummy VM
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
