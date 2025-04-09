//
//  DailyRunCompletedView.swift
//  Runr
//
//  Created by Noah Moran on 8/4/2025.
//

import SwiftUI

struct DailyRunCompletedView: View {
    let daily: DailyPlan
    let runData: RunData
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
    
    // Computed properties to derive stats from runData
    private var actualDistance: Double {  // in kilometers
        return runData.distance / 1000
    }
    
    private var actualDuration: String {
        let minutes = Int(runData.elapsedTime) / 60
        let seconds = Int(runData.elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var averagePace: String {
        guard runData.distance > 0 else { return "0:00 / km" }
        let pace = runData.elapsedTime / (runData.distance / 1000)
        let paceMinutes = Int(pace) / 60
        let paceSeconds = Int(pace) % 60
        return String(format: "%d:%02d / km", paceMinutes, paceSeconds)
    }
    
    // Use the run date as the completion time
    private var completedTime: Date {
        return runData.date
    }
    
    // Default performance insight message – adjust as needed.
    private var performanceInsight: String? {
        return "Your performance was strong, keep up the great work!"
    }
    
    // Function to get a completion message based on run type.
    private func completionMessage() -> String {
        switch daily.dailyRunType {
        case "Tempo":
            return "Great job pushing your pace! Your tempo run helps build endurance and mental toughness."
        case "Zone 2 Heart Rate":
            return "Excellent work on your aerobic base! These runs build efficiency and improve recovery."
        case "Speed":
            return "Speed work complete! These intense efforts will translate to faster race times."
        case "Long Run":
            return "Distance conquered! Your endurance is building with every long run you complete."
        case "Recovery":
            return "Smart recovery completed. This easy effort helps your body adapt to training."
        case "Rest":
            return "Rest day observed. Your discipline in recovery is as important as your training."
        default:
            return "Run complete! Every run makes you stronger and more resilient."
        }
    }
    
    // Formatter for displaying the completion time.
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with day, date, and completed badge
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
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(primaryColor)
                    }
                }
                .padding(.top, 8)
                
                // Completed badge
                HStack {
                    Text("COMPLETED")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(primaryColor)
                        )
                    
                    Spacer()
                    
                    Text("Finished at \(completedTime, formatter: timeFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Run details card
                VStack(spacing: 24) {
                    // Stats card
                    VStack {
                        HStack(spacing: 30) {
                            // Distance
                            VStack(alignment: .center) {
                                Text("\(actualDistance, specifier: "%.1f")")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(primaryColor)
                                
                                Text("kilometers")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if daily.dailyDistance > 0 {
                                    Text("Goal: \(daily.dailyDistance, specifier: "%.1f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 40)
                            
                            // Duration
                            VStack(alignment: .center) {
                                Text(actualDuration)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(primaryColor)
                                
                                Text("duration")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let planned = daily.dailyEstimatedDuration {
                                    Text("Est: \(planned)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Additional stats
                        HStack(spacing: 30) {
                            // Pace
                            VStack(alignment: .center) {
                                Text(averagePace)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(primaryColor)
                                
                                Text("avg pace")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 40)
                            
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    
                    // Completed message card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .font(.title3)
                                .foregroundColor(primaryColor)
                            
                            Text("Great Work!")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
                            Spacer()
                        }
                        
                        Text(completionMessage())
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    
                    // Performance insights card (if available)
                    if let insight = performanceInsight {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title3)
                                    .foregroundColor(primaryColor)
                                
                                Text("Performance Insight")
                                    .font(.headline)
                                    .foregroundColor(primaryColor)
                                
                                Spacer()
                            }
                            
                            Text(insight)
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
                }
                
                Spacer(minLength: 32)
                
                // Share button
                Button(action: {
                    let message = "I just completed a \(daily.dailyRunType ?? "Run") of \(actualDistance) km in \(actualDuration)!"
                    let activityController = UIActivityViewController(activityItems: [message], applicationActivities: nil)
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(activityController, animated: true)
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                        Text("Share Achievement")
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
                //.buttonStyle(ScaleButtonStyle())
            }
            .padding()
        }
        .navigationTitle("") // Remove redundant title
        .navigationBarTitleDisplayMode(.inline)
        .background(backgroundGradient.ignoresSafeArea())
    }
}

struct DailyRunCompletedView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DailyRunCompletedView(
                daily: DailyPlan(
                    day: "Monday",
                    date: Date(),
                    distance: 5.0,
                    runType: "Tempo",
                    estimatedDuration: "30 min"
                ),
                runData: RunData(
                    date: Date(),
                    distance: 5000,
                    elapsedTime: 1800,
                    routeCoordinates: []
                )
            )
        }
        .previewDisplayName("Completed Run - Tempo")
    }
}
