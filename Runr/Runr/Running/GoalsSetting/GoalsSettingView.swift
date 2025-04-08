//
//  GoalsSettingView.swift
//  Runr
//
//  Created by Noah Moran on 31/3/2025.
//

import SwiftUI
import FirebaseFirestore

struct GoalsSettingView: View {
    // MARK: - Distance-based Goals
    @State private var weeklyDistance: String = ""
    @State private var monthlyDistance: String = ""
    @State private var longestRun: String = ""
    @State private var distanceProgression: String = ""
    
    // MARK: - Personal-based Goals
    @State private var weeklyRunningDuration: String = ""
    @State private var weeklyRunFrequency: Int = 3
    @State private var paceTarget: String = ""
    
    // MARK: - Performance Goals
    @State private var personalRecords: String = ""
    @State private var averagePaceImprovement: String = ""
    @State private var negativeSplits: Bool = false
    @State private var heartRateZone: String = ""
    
    // Custom goals for each category
    @State private var distanceGoals: [Goal] = [
        Goal(title: "Weekly Distance", category: "Distance"),
                Goal(title: "Monthly Distance", category: "Distance"),
                Goal(title: "Longest Single Run", category: "Distance"),
                Goal(title: "Distance Progression", category: "Distance")
    ]
    
    @State private var performanceGoals: [Goal] = [
        Goal(title: "Personal Records", category: "Performance"),
        Goal(title: "Average Pace Improvement", category: "Performance")
    ]
    
    @State private var personalGoals: [Goal] = [
        Goal(title: "Weekly Running Duration", category: "Personal"),
        Goal(title: "Weekly Run Frequency", category: "Personal"),
        Goal(title: "Pace Target", category: "Personal")
    ]
    
    // New state: dictionary to hold selected goals per category.
    @State private var selectedGoals: [GoalCategory: [Goal]] = [
        .distance: [],
        .performance: [],
        .personal: []
    ]
    
    // MARK: - View State
    @State private var selectedCategory: GoalCategory = .distance
    @Environment(\.dismiss) var dismiss
    
    // Callback to pass back the chosen goal and its category.
    var onGoalSet: ((Goal, GoalCategory) -> Void)?
    
    enum GoalCategory: String, CaseIterable {
        case distance = "Distance"
        case performance = "Performance"
        case personal = "Personal"
    }
    
    // Helper function to return an icon based on the goal's title.
    private func iconForGoal(title: String) -> String {
        switch title {
        case "Weekly Distance": return "figure.walk"
        case "Monthly Distance": return "calendar"
        case "Longest Single Run": return "arrow.up.right"
        case "Distance Progression": return "chart.line.uptrend.xyaxis"
        case "Weekly Running Duration": return "timer"
        case "Weekly Run Frequency": return "repeat"
        case "Pace Target": return "speedometer"
        case "Personal Records": return "trophy"
        case "Average Pace Improvement": return "arrow.down"
        default: return "star.fill"
        }
    }
    
    // Computed property to flatten all selected goals into one array.
    private var allSelectedGoals: [Goal] {
        selectedGoals.values.flatMap { $0 }
    }
    
    // Helper function to get the value that is inputted into a goal so it displays when you save
    private func getTargetValue(for title: String) -> String {
        switch title {
        case "Weekly Distance": return weeklyDistance
        case "Monthly Distance": return monthlyDistance
        case "Longest Single Run": return longestRun
        case "Distance Progression": return distanceProgression
        case "Weekly Running Duration": return weeklyRunningDuration
        case "Weekly Run Frequency": return "\(weeklyRunFrequency)"
        case "Pace Target": return paceTarget
        case "Personal Records": return personalRecords
        case "Average Pace Improvement": return averagePaceImprovement
        default: return ""
        }
    }
    
    // Helper to fetch the array of goals for the current category.
    private func goalsForCurrentCategory() -> [Goal] {
        switch selectedCategory {
        case .distance: return distanceGoals
        case .personal: return personalGoals
        case .performance: return performanceGoals
        }
    }
    
    // Computed property that concatenates the titles of all selected goals across categories.
    private var allSelectedTitles: String {
        selectedGoals.values.flatMap { $0 }.map { $0.title }.joined(separator: ", ")
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Set Your Goals")
                        .font(.headline)
                    
                    Spacer()

                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                                // No need to clear selection when switching; we now preserve across categories.
                            }) {
                                Text(category.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == category ? Color.blue : Color(UIColor.systemGray5))
                                    )
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Display the pre-made goal section using GoalCard style.
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedCategory {
                        case .distance:
                            distanceGoalsSection
                        case .performance:
                            performanceGoalsSection
                        case .personal:
                            personalGoalsSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                
                // Action Button and display of selected goals.
                VStack {
                    if !allSelectedGoals.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(allSelectedGoals, id: \.title) { goal in
                                    SelectedToAddGoalsView(
                                        title: goal.title,
                                        target: getTargetValue(for: goal.title),
                                        icon: iconForGoal(title: goal.title)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .overlay(
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 4)
                                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2),
                                alignment: .top
                            )
                    }
                    
                    Button(action: {
                        Task {
                            var goalsToUpload: [Goal] = []
                                     // Use the computed property to get all selected goals
                                     for goal in allSelectedGoals {
                                         // --- Get the raw target string from the @State variable ---
                                         let targetString = getTargetValue(for: goal.title)

                                         // --- Create a Goal object ready for upload ---
                                         // Use the convenience initializer or ensure your main init handles this
                                         // IMPORTANT: Pass the input string to 'targetRaw'
                                         let goalToUpload = Goal(
                                             // id: goal.id, // Let Firestore generate ID or handle updates based on existing ID
                                             title: goal.title,
                                             category: goal.category,
                                             targetRaw: targetString // *** THIS IS THE KEY CHANGE ***
                                             // Let targetValue, targetUnit, period be set by uploadUserGoals
                                             // Or, preferably, parse/determine them here if logic is complex
                                         )

                                         // Only add if the target string is not empty
                                         if !targetString.isEmpty {
                                             goalsToUpload.append(goalToUpload)
                                         } else {
                                             print("Skipping goal '\(goal.title)' because target input is empty.")
                                             // Optional: Decide if you want to upload goals with empty targets
                                             // or delete existing ones if the input is cleared.
                                             // If you want to *delete* goals deselected or cleared,
                                             // you'll need more complex logic here or in uploadUserGoals.
                                         }
                                     }

                                     // --- Only upload if there are goals with targets ---
                                     if !goalsToUpload.isEmpty {
                                         // Upload the goals (which now have targetRaw set) to Firestore.
                                         print("Uploading \(goalsToUpload.count) goals...")
                                         await GoalsService.shared.uploadUserGoals(goals: goalsToUpload)
                                     } else {
                                          print("No valid goals with targets set were selected for upload.")
                                     }
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Set New Goal(s)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
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
    
    // MARK: - Pre-made Goal Sections using GoalCard
    
    private var distanceGoalsSection: some View {
        VStack(spacing: 16) {
            cardWrapper(goalTitle: "Weekly Distance") {
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
            }
            
            cardWrapper(goalTitle: "Monthly Distance") {
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
            }
            
            cardWrapper(goalTitle: "Longest Single Run") {
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
            }
            
            cardWrapper(goalTitle: "Distance Progression") {
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
    }
    
    private var personalGoalsSection: some View {
        VStack(spacing: 16) {
            cardWrapper(goalTitle: "Weekly Running Duration") {
                GoalCard(title: "Weekly Running Duration", icon: "timer") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target (minutes)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("0", text: $weeklyRunningDuration)
                                .keyboardType(.numberPad)
                                .font(.title3.bold())
                            Text("min")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        ProgressBar(value: 0.52)
                    }
                }
            }
            
            cardWrapper(goalTitle: "Weekly Run Frequency") {
                GoalCard(title: "Weekly Run Frequency", icon: "repeat") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of runs per week")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("\(weeklyRunFrequency)x")
                                .font(.title3.bold())
                            Spacer()
                            HStack(spacing: 16) {
                                Button(action: { if weeklyRunFrequency > 1 { weeklyRunFrequency -= 1 } }) {
                                    Image(systemName: "minus")
                                        .padding(8)
                                        .background(Color(UIColor.systemGray5))
                                        .clipShape(Circle())
                                }
                                
                                Button(action: { if weeklyRunFrequency < 7 { weeklyRunFrequency += 1 } }) {
                                    Image(systemName: "plus")
                                        .padding(8)
                                        .background(Color(UIColor.systemGray5))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        
                        ProgressBar(value: Double(weeklyRunFrequency) / 7.0)
                    }
                }
            }
            
            cardWrapper(goalTitle: "Pace Target") {
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
    }
    
    private var performanceGoalsSection: some View {
        VStack(spacing: 16) {
            cardWrapper(goalTitle: "Personal Records") {
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
            }
            
            cardWrapper(goalTitle: "Average Pace Improvement") {
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
            }
        }
    }
    
    // Helper view that wraps a GoalCard and applies a blue border if its title is among the selected goals for the current category.
    private func cardWrapper<Content: View>(goalTitle: String, @ViewBuilder content: () -> Content) -> some View {
        ZStack {
            content()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    (selectedGoals[selectedCategory]?.contains(where: { $0.title == goalTitle }) ?? false)
                    ? Color.blue : Color.clear, lineWidth: 3)
        )
        .onTapGesture {
            // Retrieve the array of selected goals for the current category.
            var currentSelections = selectedGoals[selectedCategory] ?? []
            if let index = currentSelections.firstIndex(where: { $0.title == goalTitle }) {
                // If already selected, remove it.
                currentSelections.remove(at: index)
            } else {
                // Only add if less than 3 are selected.
                if currentSelections.count < 3 {
                    // Find the goal from the appropriate goals array.
                    if let goalToAdd = goalsForCurrentCategory().first(where: { $0.title == goalTitle }) {
                        currentSelections.append(goalToAdd)
                    }
                }
            }
            selectedGoals[selectedCategory] = currentSelections
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
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct GoalsSettingView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsSettingView()
    }
}
