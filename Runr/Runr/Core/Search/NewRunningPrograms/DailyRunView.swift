//
//  DailyRunView.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import SwiftUI

struct DailyRunView: View {
    let daily: DailyPlan
    @State private var showRunningView = false  // New state variable

    // Function to get motivational message based on run type
    private func motivationalMessage() -> String {
        switch daily.dailyRunType {
        case "Tempo":
            return "Push your pace and build endurance. Focus on maintaining a challenging but sustainable speed."
        case "Zone 2 Heart Rate":
            return "Keep it steady and conversational. This run builds your aerobic base and improves fat burning."
        case "Speed":
            return "Time to get fast! Short bursts of intensity will increase your power and efficiency."
        case "Long Run":
            return "Build endurance with this longer distance. Take it slow and enjoy the journey."
        case "Recovery":
            return "Easy pace today. Let your body rebuild and strengthen from previous workouts."
        case "Rest":
            return "Rest is where the magic happens. Your body is getting stronger today."
        default:
            return "Focus on consistent effort and good form. Every step moves you forward."
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with day and date
                HStack {
                    VStack(alignment: .leading) {
                        Text(daily.day)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        if let date = daily.dailyDate {
                            Text(date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: daily.dailyDistance > 0 ? "figure.run" : "figure.walk")
                        .font(.system(size: 40))
                        .foregroundColor(daily.dailyDistance > 0 ? .blue : .green)
                }
                
                // Run type badge
                if daily.dailyDistance > 0 {
                    Text(daily.dailyRunType ?? "Regular Run")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.2))
                        )
                } else {
                    Text("Rest Day")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                }
                
                // Run details
                VStack(alignment: .leading, spacing: 12) {
                    if daily.dailyDistance > 0 {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("Distance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(daily.dailyDistance, specifier: "%.1f") km")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            if let duration = daily.dailyEstimatedDuration {
                                Divider()
                                    .frame(height: 40)
                                VStack(alignment: .leading) {
                                    Text("Duration")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(duration)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    
                    // Motivational message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Focus")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(motivationalMessage())
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                }
                
                Spacer()
                
                // Start button that navigates to RunningView
                if daily.dailyDistance > 0 {
                    Button(action: {
                        showRunningView = true  // Trigger navigation
                    }) {
                        HStack {
                            Spacer()
                            Text("Start Run")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                
                // Hidden NavigationLink that activates when showRunningView becomes true
                NavigationLink(destination: RunningView(targetDistance: daily.dailyDistance), isActive: $showRunningView) {
                    EmptyView()
                }
                .hidden()

            }
            .padding()
        }
        .navigationTitle(daily.day)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}

struct DailyRunView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                DailyRunView(daily: DailyPlan(
                    day: "Monday",
                    date: Date(),
                    distance: 5.0,
                    runType: "Tempo",
                    estimatedDuration: "30 min",
                    workoutDetails: [
                        "5 min easy warm-up",
                        "20 min at tempo pace (moderately hard)",
                        "5 min cool-down"
                    ]
                ))
            }
            .previewDisplayName("Running Day")
            
            NavigationView {
                DailyRunView(daily: DailyPlan(
                    day: "Wednesday",
                    date: Date(),
                    distance: 0.0,
                    runType: "Rest"
                ))
            }
            .previewDisplayName("Rest Day")
        }
    }
}
