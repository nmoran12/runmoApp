//
//  DailyRunView.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import SwiftUI

struct DailyRunView: View {
    let daily: DailyPlan
    @State private var showRunningView = false
    @Environment(\.colorScheme) var colorScheme
    
    // Colors and gradients
    private var primaryColor: Color {
        switch daily.dailyRunType {
        case "Tempo": return Color.orange
        case "Zone 2 Heart Rate": return Color.green
        case "Speed": return Color.red
        case "Long Run": return Color.purple
        case "Recovery": return Color.blue
        case "Rest": return Color.green
        default: return Color.blue
        }
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                primaryColor.opacity(colorScheme == .dark ? 0.3 : 0.1),
                Color(UIColor.systemBackground)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
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
            VStack(alignment: .leading, spacing: 24) {
                // Header with day, date and icon
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(daily.day)
                            .font(.system(size: 36, weight: .bold))
                        
                        if let date = daily.dailyDate {
                            Text(date, style: .date)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(primaryColor.opacity(0.2))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: daily.dailyDistance > 0 ? "figure.run" : "figure.walk")
                            .font(.system(size: 32))
                            .foregroundColor(primaryColor)
                    }
                }
                .padding(.top, 8)
                
                // Run type badge with color based on run type
                HStack {
                    Text(daily.dailyDistance > 0 ? (daily.dailyRunType ?? "Regular Run") : "Rest Day")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(primaryColor)
                        )
                    
                    Spacer()
                }
                
                // Run details card
                VStack(spacing: 24) {
                    if daily.dailyDistance > 0 {
                        // Distance and duration in a nice card
                        HStack(spacing: 30) {
                            // Distance
                            VStack(alignment: .center) {
                                Text("\(daily.dailyDistance, specifier: "%.1f")")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(primaryColor)
                                
                                Text("kilometers")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 40)
                            
                            // Duration if available
                            if let duration = daily.dailyEstimatedDuration {
                                VStack(alignment: .center) {
                                    Text(duration)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(primaryColor)
                                    
                                    Text("duration")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                    }
                    
                    // Motivational message in a card with icon
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "quote.bubble")
                                .font(.title3)
                                .foregroundColor(primaryColor)
                            
                            Text("Today's Focus")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
                            Spacer()
                        }
                        
                        Text(motivationalMessage())
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    
                }
                
                Spacer(minLength: 32)
                
                // Start button with gradient and animation
                if daily.dailyDistance > 0 {
                    Button(action: {
                        withAnimation {
                            showRunningView = true
                        }
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.headline)
                            Text("Start Run")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: primaryColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Hidden NavigationLink
                NavigationLink(destination: RunningView(targetDistance: daily.dailyDistance), isActive: $showRunningView) {
                    EmptyView()
                }
                .hidden()
            }
            .padding()
        }
        .navigationTitle("") // Remove title as it's redundant with the large day text
        .navigationBarTitleDisplayMode(.inline)
        .background(backgroundGradient.ignoresSafeArea())
    }
}

// Custom button style with scale effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
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
            .previewDisplayName("Running Day - Tempo")
            
            NavigationView {
                DailyRunView(daily: DailyPlan(
                    day: "Wednesday",
                    date: Date(),
                    distance: 0.0,
                    runType: "Rest"
                ))
            }
            .previewDisplayName("Rest Day")
            
            NavigationView {
                DailyRunView(daily: DailyPlan(
                    day: "Friday",
                    date: Date(),
                    distance: 8.0,
                    runType: "Long Run",
                    estimatedDuration: "60 min"
                ))
            }
            .previewDisplayName("Long Run Day")
            .preferredColorScheme(.dark)
        }
    }
}
