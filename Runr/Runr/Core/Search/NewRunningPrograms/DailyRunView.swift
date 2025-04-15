//
//  DailyRunView.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import SwiftUI

struct DailyRunView: View {
    let daily: DailyPlan
    @EnvironmentObject var programVM: NewRunningProgramViewModel
    @State private var showRunningView = false
    @Environment(\.colorScheme) var colorScheme
    
    // Primary color based on run type
    private var primaryColor: Color {
        switch daily.dailyRunType {
        case "Tempo": return Color.orange
        case "Zone 2 Heart Rate": return Color.green
        case "Speed": return Color.red
        case "Long Run": return Color.purple
        case "Recovery": return Color.blue
        case "Rest": return Color.gray
        default: return Color.blue
        }
    }
    
    var body: some View {
        NavigationView {
        ZStack {
            // Background gradient/light tone with plenty of white space
            LinearGradient(gradient: Gradient(colors: [Color.white, Color(UIColor.systemGray6)]),
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Header: Day, Date & Icon Badge
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(daily.day)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundColor(primaryColor)
                            if let date = daily.dailyDate {
                                Text(date, style: .date)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            Image(systemName: daily.dailyDistance > 0 ? runTypeIcon() : "figure.walk")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(primaryColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Run Type Badge as a capsule
                    HStack {
                        Text(daily.dailyDistance > 0 ? (daily.dailyRunType ?? "Regular Run") : "Rest Day")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().stroke(primaryColor, lineWidth: 2))
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Recommended Pace (if applicable)
                    if daily.dailyDistance > 0, let pace = recommendedPace() {
                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Text("Recommended Pace: \(pace) min/km")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Distance & Estimated Duration Card
                    if daily.dailyDistance > 0 {
                        HStack {
                            VStack {
                                Text("\(daily.dailyDistance, specifier: "%.1f")")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(primaryColor)
                                Text("km")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .padding(.vertical)
                            
                            if let duration = daily.dailyEstimatedDuration {
                                VStack {
                                    Text(duration)
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("est. time")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                    }
                    
                    // Motivational Message Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 18))
                                .foregroundColor(primaryColor)
                            Text("Today's Focus")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(primaryColor)
                        }
                        Text(motivationalMessage())
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineSpacing(5)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // Start Run Button
                    if daily.dailyDistance > 0 {
                        Button(action: { withAnimation { showRunningView = true } }) {
                            Text("Start Run")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(primaryColor)
                                )
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    // IMPORTANT: Add a hidden NavigationLink that becomes active when showRunningView is true.
                    NavigationLink(
                        destination: RunningView().environmentObject(programVM),
                        isActive: $showRunningView
                    ) {
                        EmptyView()
                    }
                }
                    
                    Spacer(minLength: 30)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.clear)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
    
    // Helper for recommended pace
    private func recommendedPace() -> String? {
        if let runTypeStr = daily.dailyRunType,
           let runType = RunType(rawValue: runTypeStr) {
            return PaceCalculator.formattedRecommendedPace(for: runType, targetTimeSeconds: programVM.targetTimeSeconds)
        }
        return nil
    }
    
    // Helper to choose the appropriate run type icon
    private func runTypeIcon() -> String {
        switch daily.dailyRunType {
        case "Tempo": return "speedometer"
        case "Zone 2 Heart Rate": return "heart.fill"
        case "Speed": return "bolt.fill"
        case "Long Run": return "map.fill"
        case "Recovery": return "arrow.clockwise"
        case "Rest": return "moon.zzz.fill"
        default: return "figure.run"
        }
    }
    
    // Motivational message based on run type
    private func motivationalMessage() -> String {
        switch daily.dailyRunType {
        case "Tempo":
            return "Push your pace and build endurance. Maintain a challenging yet sustainable effort."
        case "Zone 2 Heart Rate":
            return "Keep it steady and conversational to efficiently boost your aerobic base."
        case "Speed":
            return "Accelerate with short bursts of speed to boost your power and efficiency."
        case "Long Run":
            return "Focus on steady endurance and enjoy the journey in every step."
        case "Recovery":
            return "Take it easy, letting your body recover and rebuild for the next challenge."
        case "Rest":
            return "Rest up today—recharge and let your body prepare for tomorrow's strides."
        default:
            return "Keep focused on maintaining great form; every run counts."
        }
    }
}
