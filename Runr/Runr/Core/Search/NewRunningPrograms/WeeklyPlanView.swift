//
//  WeeklyPlanView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct WeeklyPlanView: View {
    let plan: WeeklyPlan // The specific week plan
        let weekIndex: Int // Index of this week within the whole program
    @EnvironmentObject var viewModel: NewRunningProgramViewModel
        @State private var selectedDay: DailyPlan?
    
    private var completionPercentage: Double {
        let completedDays = plan.dailyPlans.filter { $0.isCompleted }.count
        return Double(completedDays) / Double(plan.dailyPlans.count)
    }


    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    WeeklyPlanHeroSection(plan: plan, completionPercentage: completionPercentage)
                    // --- Pass viewModel and weekIndex down ---
                    DailyScheduleSection(
                        plan: plan,
                        weekIndex: weekIndex, // Pass the week index
                        selectedDay: $selectedDay,
                        viewModel: _viewModel // Pass the view model
                    )
                    TipsView()
                }
                .padding()
            }
            .navigationTitle(plan.weekTitle) // Use week title
            .navigationBarTitleDisplayMode(.inline)
        }
    }


struct WeeklyPlanHeroSection: View {
    let plan: WeeklyPlan
    let completionPercentage: Double

    var body: some View {
        VStack(spacing: 16) {
            // Week title header
            Text(plan.weekTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            HStack {
            }
            .padding(.horizontal)
            
            // Progress ring to show weekly completion
            ProgressRingView(completionPercentage: completionPercentage)
                .padding(.top, 8)
            
            // Combined stats card using style similar to ProfileStatsView
            VStack(spacing: 16) {
                HStack {
                    StatItemView(title: "Workouts", value: "\(plan.weeklyTotalWorkouts)")
                    Divider()
                        .frame(height: 40)
                    StatItemView(
                        title: "Distance",
                        value: String(format: "%.1f", plan.weeklyTotalDistance) + " km"
                    )

                }
            }
            
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}


    struct ProgressRingView: View {
        let completionPercentage: Double

        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(completionPercentage))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(completionPercentage * 100))%")
                        .font(.system(size: 24, weight: .bold))
                    Text("Complete")
                        .font(.subheadline)
                }
            }
        }
    }

// In WeeklyPlanView.swift

struct DailyScheduleSection: View {
    let plan: WeeklyPlan
    let weekIndex: Int // Receive week index
    @Binding var selectedDay: DailyPlan?
    @EnvironmentObject var viewModel: NewRunningProgramViewModel


    // Helper to generate a dummy RunData from a DailyPlan.
    // Adjust this function as needed to reflect your actual run stats.
    private func runDataFromDailyPlan(_ daily: DailyPlan) -> RunData {
        // Assume daily.dailyDistance is in kilometers; convert to meters.
        let distanceMeters = daily.dailyDistance * 1000
        // Use a dummy elapsed time (30 minutes, i.e. 1800 seconds) – replace with real data when available.
        let elapsedTime = 1800.0
        return RunData(date: daily.dailyDate ?? Date(),
                       distance: distanceMeters,
                       elapsedTime: elapsedTime,
                       routeCoordinates: [])     // Dummy value; add coordinates if available.
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Schedule")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 4)

            ForEach(Array(plan.dailyPlans.enumerated()), id: \.element.id) { dayIndex, daily in
                NavigationLink(
                    destination: daily.isCompleted
                        ? AnyView(
                            DailyRunCompletedView(
                                daily: daily,
                                runData: runDataFromDailyPlan(daily)
                            )
                          )
                        : AnyView(DailyRunView(daily: daily)),
                    tag: daily,
                    selection: $selectedDay
                ) {
                    DailyRunCard(
                        daily: daily,
                        isSelected: selectedDay?.id == daily.id,
                        weekIndex: weekIndex,
                        dayIndex: dayIndex,
                        viewModel: viewModel  // Alternatively, if DailyRunCard uses the same view model, make it also an environment object.
                    )
                }



            }
        }
        .padding(.vertical)
    }
}


struct TipsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Tips")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                TipRow(tip: "Hydrate before and after each run", iconName: "drop.fill")
                TipRow(tip: "Stretch for at least 5 minutes before starting", iconName: "figure.walk")
                TipRow(tip: "Focus on maintaining consistent pace", iconName: "speedometer")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
            )
        }
    }
}

struct TipRow: View {
    let tip: String
    let iconName: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(tip)
                .font(.subheadline)
        }
    }
}

struct WeeklyPlanView_Previews: PreviewProvider {
    static var previews: some View {
        // Create sample data needed for the preview
        let sampleDailyPlans = [ /* ... your sample daily plans ... */
            DailyPlan(day: "Monday", distance: 5.0),
            DailyPlan(day: "Tuesday", distance: 7.5),
            DailyPlan(day: "Wednesday", distance: 0.0),
            DailyPlan(day: "Thursday", distance: 10.0),
            DailyPlan(day: "Friday", distance: 5.0), // Adjusted sample data
            DailyPlan(day: "Saturday", distance: 12.0),
            DailyPlan(day: "Sunday", distance: 8.0)
        ]
        let sampleWeeklyPlan = WeeklyPlan(
            weekNumber: 1,
            weekTitle: "Week 1 Preview",
            weeklyTotalWorkouts: 6,
            weeklyTotalDistance: sampleDailyPlans.reduce(0) { $0 + $1.dailyDistance },
            dailyPlans: sampleDailyPlans,
            weeklyDescription: "This is a sample description for preview"
        )
        // --- Create a dummy ViewModel instance JUST for the preview ---
        let previewViewModel = NewRunningProgramViewModel()
        // --- Optionally set some preview state on the VM if needed ---
        // previewViewModel.currentProgram = sampleProgram // If needed

        NavigationView {
            WeeklyPlanView(
                plan: sampleWeeklyPlan,
                weekIndex: 0
            )
            .environmentObject(previewViewModel)  // provide the same instance
        }

        .preferredColorScheme(.light)
    }
}
