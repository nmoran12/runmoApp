//
//  ProfileStatsView.swift
//  Runr
//
//  Created by Noah Moran on 31/3/2025.
//

import SwiftUI
import Kingfisher

struct ProfileStatsView: View {
    let user: User
    @State private var runs: [RunData] = []
    @State private var selectedTimeframe: Timeframe = .weekly

    enum Timeframe: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
        case allTime = "All Time"
    }
    
    // Filter runs based on the selected timeframe.
    var filteredRuns: [RunData] {
        let now = Date()
        switch selectedTimeframe {
        case .weekly:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            return runs.filter { $0.date >= oneWeekAgo }
        case .monthly:
            let oneMonthAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            return runs.filter { $0.date >= oneMonthAgo }
        case .yearly:
            let oneYearAgo = Calendar.current.date(byAdding: .day, value: -365, to: now)!
            return runs.filter { $0.date >= oneYearAgo }
        case .allTime:
            return runs
        }
    }
    
    // Computed stats.
    var runCount: Int {
        filteredRuns.count
    }
    
    var totalDistance: Double {
        filteredRuns.reduce(0) { $0 + $1.distance } / 1000
    }
    
    var totalTime: Double {
        filteredRuns.reduce(0) { $0 + $1.elapsedTime }
    }
    
    var averagePace: Double {
        totalDistance > 0 ? (totalTime / 60) / totalDistance : 0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with profile picture and title.
                HStack(spacing: 16) {
                    if let urlString = user.profileImageUrl, let url = URL(string: urlString) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.secondary)
                    }
                    Text("\(user.username) Stats")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Timeframe selector.
                HStack {
                    Text("Timeframe")
                        .font(.headline)
                    Spacer()
                    Picker("", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                
                // Combined stats card.
                CombinedStatsCardView(
                    runCount: runCount,
                    totalDistance: totalDistance,
                    totalTime: totalTime,
                    averagePace: averagePace
                )
                .padding(.horizontal)
                
                // Overall Pace Chart.
                if !filteredRuns.isEmpty {
                    OverallPaceChartView(runs: filteredRuns)
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
                
                if !filteredRuns.isEmpty {
                    OverallHeartRateZonesView(runs: filteredRuns)
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
                
                if !filteredRuns.isEmpty {
                    HeartRateZoneChartView(runs: filteredRuns)
                        .padding(.top, 16)
                        .padding(.horizontal) // around the card

                }

                


                
                // Personal Bests section.
                VStack(alignment: .leading, spacing: 8) {
                    BestEffortsCardView()
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                runs = try await AuthService.shared.fetchUserRuns(for: user.id)
            } catch {
                print("DEBUG: Failed to fetch runs: \(error.localizedDescription)")
            }
        }
    }
}

// Combined stats card that shows all four stats in one card.
struct CombinedStatsCardView: View {
    let runCount: Int
    let totalDistance: Double
    let totalTime: Double
    let averagePace: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatItemView(title: "Runs", value: "\(runCount)")
                Divider()
                    .frame(height: 40)
                StatItemView(title: "Distance", value: "\(totalDistance.formatted(.number.precision(.fractionLength(2)))) km")
            }
            HStack {
                StatItemView(title: "Time", value: formatTime(totalTime))
                Divider()
                    .frame(height: 40)
                StatItemView(title: "Avg Pace", value: "\(averagePace.formatted(.number.precision(.fractionLength(1)))) min/km")
            }
        }
        .padding()
        .background(Color.white)
        .frame(maxWidth: .infinity)    
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // Helper function to format elapsed time.
    func formatTime(_ totalTime: Double) -> String {
        let totalSeconds = Int(totalTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
}

// A simple view representing a single stat item.
struct StatItemView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        ProfileStatsView(
            user: User(
                id: "123",
                username: "Spiderman",
                profileImageUrl: "https://example.com/profile.jpg",
                email: "spiderman@avengers.com",
                realName: "Peter Parker"
            )
        )
    }
}

