//
//  WeeklyPlanView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct WeeklyPlanView: View {
    let plan: WeeklyPlan
    @State private var selectedDay: DailyPlan?
    
    private var completionPercentage: Double {
        let completedDays = plan.dailyPlans.filter { $0.dailyDistance > 0 }.count
        return Double(completedDays) / Double(plan.dailyPlans.count)
    }

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    WeeklyPlanHeroSection(plan: plan, completionPercentage: completionPercentage)
                    DailyScheduleSection(plan: plan, selectedDay: $selectedDay)
                    TipsView()
                }
                .padding()
            }
            .navigationTitle("Weekly Plan")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    struct WeeklyPlanHeroSection: View {
        let plan: WeeklyPlan
        let completionPercentage: Double

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
                
                VStack(spacing: 16) {
                    Text(plan.weekTitle)
                        .font(.system(size: 28, weight: .bold))
                    ProgressRingView(completionPercentage: completionPercentage)
                    HStack(spacing: 20) {
                        SummaryCard(title: "Workouts", value: "\(plan.weeklyTotalWorkouts)", iconName: "figure.run")
                        SummaryCard(title: "Distance", value: "\(plan.weeklyTotalDistance) km", iconName: "map")
                    }
                }
                .padding()
            }
            .padding(.bottom)
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

    struct DailyScheduleSection: View {
        let plan: WeeklyPlan
        @Binding var selectedDay: DailyPlan?

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily Schedule")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)
                
                ForEach(plan.dailyPlans) { daily in
                    NavigationLink(
                        destination: DailyRunView(daily: daily),
                        tag: daily,
                        selection: $selectedDay
                    ) {
                        DailyRunCard(daily: daily, isSelected: selectedDay?.id == daily.id)
                    }
                }
            }
            .padding(.vertical)
        }
    }


struct SummaryCard: View {
    let title: String
    let value: String
    let iconName: String
    
    var body: some View {
        VStack {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .padding(.bottom, 2)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
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
        let sampleDailyPlans = [
            DailyPlan(day: "Monday", distance: 5.0),
            DailyPlan(day: "Tuesday", distance: 7.5),
            DailyPlan(day: "Wednesday", distance: 0.0),
            DailyPlan(day: "Thursday", distance: 10.0),
            DailyPlan(day: "Friday", distance: 100.0),
            DailyPlan(day: "Saturday", distance: 12.0),
            DailyPlan(day: "Sunday", distance: 8.0)
        ]
        let sampleWeeklyPlan = WeeklyPlan(
            weekNumber: 1,
            weekTitle: "Week 1",
            weeklyTotalWorkouts: 6,
            weeklyTotalDistance: sampleDailyPlans.reduce(0) { $0 + $1.dailyDistance },
            dailyPlans: sampleDailyPlans,
            weeklyDescription: "This is a sample description"
        )
        NavigationView {
            WeeklyPlanView(plan: sampleWeeklyPlan)
        }
        .preferredColorScheme(.light)
    }
}
