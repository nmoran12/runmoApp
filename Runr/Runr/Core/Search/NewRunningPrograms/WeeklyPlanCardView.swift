//
//  WeeklyPlanCardView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct WeeklyPlanCardView: View {
    let plan: WeeklyPlan

    var body: some View {
        NavigationLink(destination: WeeklyPlanView(plan: plan)) {
            VStack(alignment: .leading, spacing: 8) {
                // Placeholder header text
                Text("Week 1")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Placeholder summary information
                HStack {
                    Text("Workouts: 6")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Total: 55.0 km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Placeholder daily breakdown
                Text("Monday: 5.0 km")
                    .font(.body)
                Text("Tuesday: 7.5 km")
                    .font(.body)
                Text("Wednesday: Rest Day")
                    .font(.body)
                Text("Thursday: 10.0 km")
                    .font(.body)
                Text("Friday: 5.0 km")
                    .font(.body)
                Text("Saturday: 12.0 km")
                    .font(.body)
                Text("Sunday: 8.0 km")
                    .font(.body)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct WeeklyPlanCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Even though the plan is still passed in, it won't affect our placeholder text.
        WeeklyPlanCardView(plan: WeeklyPlan(
            weekNumber: 1,
            weekTitle: "Week 1",
            weeklyTotalWorkouts: 6,
            weeklyTotalDistance: 55.0,
            dailyPlans: [],  // This won't be used
            weeklyDescription: "This is a sample description"
        ))
        .previewLayout(.sizeThatFits)
    }
}
