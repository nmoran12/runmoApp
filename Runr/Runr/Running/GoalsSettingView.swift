//
//  GoalsSettingView.swift
//  Runr
//
//  Created by Noah Moran on 31/3/2025.
//

import SwiftUI

struct GoalsSettingView: View {
    // MARK: - Distance-based Goals
    @State private var weeklyDistance: String = ""
    @State private var monthlyDistance: String = ""
    @State private var longestRun: String = ""
    @State private var distanceProgression: String = ""
    
    // MARK: - Time-based Goals
    @State private var weeklyDuration: String = ""
    @State private var runFrequency: Int = 3
    @State private var paceTarget: String = ""
    
    // MARK: - Performance Goals
    @State private var personalRecords: String = ""
    @State private var averagePaceImprovement: String = ""
    @State private var negativeSplits: Bool = false
    @State private var heartRateZone: String = ""
    
    // MARK: - Streak and Consistency Goals
    @State private var consecutiveDays: Int = 0
    @State private var dontBreakChain: Bool = false
    @State private var monthlyStreak: Int = 0
    
    // MARK: - Event Preparation
    @State private var trainingPlan: String = ""
    @State private var raceDayTarget: String = ""
    @State private var qualificationTime: String = ""
    
    // MARK: - Body Metrics
    @State private var weightGoal: String = ""
    @State private var restingHeartRate: String = ""
    @State private var vo2MaxTarget: String = ""
    
    // MARK: - Social/Community Goals
    @State private var groupChallenges: Bool = false
    @State private var virtualRaces: Bool = false
    @State private var leaderboardGoal: String = ""
    
    // MARK: - View State
    @State private var selectedCategory: GoalCategory = .distance
    @Environment(\.dismiss) var dismiss
    
    enum GoalCategory: String, CaseIterable {
        case distance = "Distance"
        case time = "Time"
        case performance = "Performance"
        case streak = "Streak"
        case event = "Event"
        case metrics = "Metrics"
        case social = "Social"
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Set Your Goals")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Save") {
                        // Save the goals settings
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedCategory {
                        case .distance:
                            distanceGoalsSection
                        case .time:
                            timeGoalsSection
                        case .performance:
                            performanceGoalsSection
                        case .streak:
                            streakGoalsSection
                        case .event:
                            eventGoalsSection
                        case .metrics:
                            metricsGoalsSection
                        case .social:
                            socialGoalsSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                
                // Action Button
                VStack {
                    Button(action: {
                        // Action to finalize setting the goals
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Set New Goal")
                        }
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .background(
                    Color(.systemBackground)
                        .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: -4)
                )
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Goal Sections
    
    private var distanceGoalsSection: some View {
        VStack(spacing: 16) {
            GoalCard(title: "Weekly Distance", icon: "figure.walk") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target (km)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0", text: $weeklyDistance)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                        
                        Text("km")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: 0.3)
                }
            }
            
            GoalCard(title: "Monthly Distance", icon: "calendar") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target (km)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0", text: $monthlyDistance)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                        
                        Text("km")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: 0.45)
                }
            }
            
            GoalCard(title: "Longest Single Run", icon: "arrow.up.right") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target (km)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0", text: $longestRun)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                        
                        Text("km")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: 0.6)
                }
            }
            
            GoalCard(title: "Distance Progression", icon: "chart.line.uptrend.xyaxis") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Milestone (e.g., 5K to 10K)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., 5K to 10K", text: $distanceProgression)
                        .font(.title3)
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var timeGoalsSection: some View {
        VStack(spacing: 16) {
            GoalCard(title: "Weekly Running Duration", icon: "timer") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target (minutes)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0", text: $weeklyDuration)
                            .keyboardType(.numberPad)
                            .font(.title3.bold())
                        
                        Text("min")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: 0.52)
                }
            }
            
            GoalCard(title: "Weekly Run Frequency", icon: "repeat") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number of runs per week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(runFrequency)x")
                            .font(.title3.bold())
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: { if runFrequency > 1 { runFrequency -= 1 } }) {
                                Image(systemName: "minus")
                                    .padding(8)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: { if runFrequency < 7 { runFrequency += 1 } }) {
                                Image(systemName: "plus")
                                    .padding(8)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: Double(runFrequency) / 7.0)
                }
            }
            
            GoalCard(title: "Pace Target", icon: "speedometer") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target (min/km)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0", text: $paceTarget)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                        
                        Text("min/km")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: 0.75)
                }
            }
        }
    }
    
    private var performanceGoalsSection: some View {
        VStack(spacing: 16) {
            GoalCard(title: "Personal Records", icon: "trophy") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., 25min 5K", text: $personalRecords)
                        .font(.title3)
                        .padding(.vertical, 4)
                }
            }
            
            GoalCard(title: "Average Pace Improvement", icon: "arrow.down") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Improvement (seconds/km)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0", text: $averagePaceImprovement)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                        
                        Text("sec/km")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: 0.4)
                }
            }
            
            GoalCard(title: "Negative Splits", icon: "chart.bar.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Run second half faster than first")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Toggle("Enable", isOn: $negativeSplits)
                        .padding(.vertical, 4)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            
            GoalCard(title: "Heart Rate Zone", icon: "heart") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Zone")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Zone 3", text: $heartRateZone)
                        .font(.title3)
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var streakGoalsSection: some View {
        VStack(spacing: 16) {
            GoalCard(title: "Consecutive Running Days", icon: "flame") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target (days)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(consecutiveDays)")
                            .font(.title3.bold())
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: { if consecutiveDays > 0 { consecutiveDays -= 1 } }) {
                                Image(systemName: "minus")
                                    .padding(8)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: { consecutiveDays += 1 }) {
                                Image(systemName: "plus")
                                    .padding(8)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: min(Double(consecutiveDays) / 30.0, 1.0))
                }
            }
            
            GoalCard(title: "Don't Break the Chain", icon: "link") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Run every day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Toggle("Enable", isOn: $dontBreakChain)
                        .padding(.vertical, 4)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            
            GoalCard(title: "Monthly Running Streaks", icon: "calendar") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target (days per month)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(monthlyStreak)")
                            .font(.title3.bold())
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: { if monthlyStreak > 0 { monthlyStreak -= 1 } }) {
                                Image(systemName: "minus")
                                    .padding(8)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: { if monthlyStreak < 31 { monthlyStreak += 1 } }) {
                                Image(systemName: "plus")
                                    .padding(8)
                                    .background(Color(UIColor.systemGray5))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: Double(monthlyStreak) / 31.0)
                }
            }
        }
    }
    
    private var eventGoalsSection: some View {
        VStack(spacing: 16) {
            GoalCard(title: "Training Plan", icon: "list.bullet") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Training Schedule")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., 12-week marathon plan", text: $trainingPlan)
                        .font(.title3)
                        .padding(.vertical, 4)
                }
            }
            
            GoalCard(title: "Race Day Target", icon: "flag.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completion Goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Finish in under 2 hours", text: $raceDayTarget)
                        .font(.title3)
                        .padding(.vertical, 4)
                }
            }
            
            GoalCard(title: "Qualification Time", icon: "stopwatch") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., 3:30:00 for Boston", text: $qualificationTime)
                        .font(.title3)
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var metricsGoalsSection: some View {
        VStack(spacing: 16) {
            GoalCard(title: "Weight Management", icon: "scalemass") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target (kg)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0", text: $weightGoal)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                        
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: 0.65)
                }
            }
            
            GoalCard(title: "Resting Heart Rate", icon: "heart.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target (bpm)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0", text: $restingHeartRate)
                            .keyboardType(.numberPad)
                            .font(.title3.bold())
                        
                        Text("bpm")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: 0.7)
                }
            }
            
            GoalCard(title: "VO2 Max", icon: "lungs.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("0", text: $vo2MaxTarget)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold())
                        
                        Text("ml/kg/min")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    ProgressBar(value: 0.55)
                }
            }
        }
    }
    
    private var socialGoalsSection: some View {
        VStack(spacing: 16) {
            GoalCard(title: "Group Challenges", icon: "person.3") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Participate in group events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Toggle("Enable", isOn: $groupChallenges)
                        .padding(.vertical, 4)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            
            GoalCard(title: "Virtual Races", icon: "network") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Join virtual competitions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Toggle("Enable", isOn: $virtualRaces)
                        .padding(.vertical, 4)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            
            GoalCard(title: "Leaderboard Ranking", icon: "list.number") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Placement")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Top 10%", text: $leaderboardGoal)
                        .font(.title3)
                        .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Component Views

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .primary : .primary)
                .cornerRadius(20)
        }
    }
}

struct GoalCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 8)
                    .opacity(0.1)
                    .foregroundColor(Color.blue)
                    .cornerRadius(4)
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: 8)
                    .foregroundColor(Color.blue)
                    .cornerRadius(4)
            }
        }
        .frame(height: 8)
    }
}

struct GoalsSettingView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsSettingView()
    }
}
