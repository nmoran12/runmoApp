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
        case "Tempo": return .orange
        case "Zone 2 Heart Rate": return .green
        case "Speed": return .red
        case "Long Run": return .purple
        case "Recovery": return .blue
        case "Rest": return .gray
        default: return .blue
        }
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Header Card
                    VStack(spacing: 16) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(daily.day)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(primaryColor)
                                if let date = daily.dailyDate {
                                    Text(date, style: .date)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                Image(systemName: daily.dailyDistance > 0 ? runTypeIcon() : "figure.walk")
                                    .font(.system(size: 24))
                                    .foregroundColor(primaryColor)
                            }
                        }
                        HStack {
                            Text(daily.dailyDistance > 0 ? (daily.dailyRunType ?? "") : "Rest Day")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(primaryColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().stroke(primaryColor, lineWidth: 1.5))

                            Spacer()

                            if daily.dailyDistance > 0, let pace = recommendedPace() {
                                Label("Recommended Pace: \(pace)", systemImage: "stopwatch")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    // MARK: Distance & Time Card
                    if daily.dailyDistance > 0 {
                        HStack {
                            VStack {
                                Text(String(format: "%.1f", daily.dailyDistance))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(primaryColor)
                                Text("km")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if let duration = daily.dailyEstimatedDuration {
                                VStack {
                                    Text(duration)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("est. time")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    }

                    // MARK: Motivational Focus Card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Today's Focus", systemImage: "quote.bubble")
                            .font(.headline)
                            .foregroundColor(primaryColor)
                        Text(motivationalMessage())
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(5)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    // MARK: Start Run Button
                    if daily.dailyDistance > 0 {
                        Button(action: { showRunningView = true }) {
                            Text("Start Run")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .shadow(color: primaryColor.opacity(0.3), radius: 6, x: 0, y: 3)
                    }

                    // Invisible NavigationLink
                    NavigationLink(
                        destination: RunningView(targetDistance: daily.dailyDistance)
                                            .environmentObject(programVM),
                        isActive: $showRunningView
                    ) {
                        EmptyView()
                    }

                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers
    private func recommendedPace() -> String? {
        if let runTypeStr = daily.dailyRunType,
           let runType = RunType(rawValue: runTypeStr) {
            return PaceCalculator.formattedRecommendedPace(for: runType,
                                                           targetTimeSeconds: programVM.targetTimeSeconds)
        }
        return nil
    }

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
