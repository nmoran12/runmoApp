//
//  ShowCurrentDayPlanView.swift
//  Runr
//
//  Created by Noah Moran on 9/4/2025.
//

import SwiftUI

struct ShowCurrentDayPlanView: View {
    @EnvironmentObject var viewModel: NewRunningProgramViewModel

    var body: some View {
        Group {
            if let todayPlan = viewModel.getTodaysDailyPlan() {
                // For run or rest days: if plan exists, show respective information.
                HStack(spacing: 12) {
                    if todayPlan.dailyDistance > 0 {
                        // For a run day, display details for a run day.
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today: \(todayPlan.day)")
                                .font(.headline)
                            
                            HStack {
                                Text("Run Type:")
                                    .font(.subheadline)
                                Text(todayPlan.dailyRunType ?? "Unknown")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Distance:")
                                    .font(.subheadline)
                                Text("\(todayPlan.dailyDistance, specifier: "%.1f") km")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    } else {
                        // For a rest day, show a simple rest message.
                        VStack(alignment: .center, spacing: 8) {
                            Text("Today: \(todayPlan.day)")
                                .font(.headline)
                            Text("Rest Day")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Spacer()
                    
                    // Show the "play" button only if it's a run day (non-zero distance).
                    if todayPlan.dailyDistance > 0 {
                        NavigationLink(destination: RunningView(targetDistance: todayPlan.dailyDistance)
                                        .environmentObject(viewModel)) {
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            } else {
                // When no plan exists for today, display an improved card.
                HStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                        .padding(.leading, 12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No run plan for today")
                            .font(.headline)
                        
                        Text("Take a rest, stretch a bit and get ready for the next day.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }
}

struct ShowCurrentDayPlanView_Previews: PreviewProvider {
    static var previews: some View {
        // Create dummy daily plans for preview:
        let dummyRunPlan = DailyPlan(
            day: "Wednesday",
            date: Date(), // Assume today
            distance: 7.5,
            runType: "Tempo",
            estimatedDuration: "35:00",
            workoutDetails: nil,
            isCompleted: false
        )
        
        let dummyRestPlan = DailyPlan(
            day: "Wednesday",
            date: Date(), // Assume today
            distance: 0.0,
            runType: nil,
            estimatedDuration: nil,
            workoutDetails: nil,
            isCompleted: false
        )
        
        // For preview, create a view model instance and set the override.
        let viewModel = NewRunningProgramViewModel()
        // Uncomment one of the lines below to preview a run day or a rest day.
        viewModel.todaysDailyPlanOverride = dummyRunPlan   // Run day preview.
        // viewModel.todaysDailyPlanOverride = dummyRestPlan  // Rest day preview.
        
        return ShowCurrentDayPlanView()
            .environmentObject(viewModel)
            .previewLayout(.sizeThatFits)
    }
}
