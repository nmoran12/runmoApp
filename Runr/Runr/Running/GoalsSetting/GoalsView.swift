//
//  GoalsView.swift
//  Runr
//
//  Created by Noah Moran on 2/4/2025.
//

import SwiftUI

struct GoalsView: View {
    enum GoalType: String, CaseIterable {
        case distance = "Distance"
        case performance = "Performance"
        case personal = "Personal" // Here "Personal" maps to the Time category.
    }
    
    @State private var selectedGoalType: GoalType = .distance
    @State private var showingGoalSettingView = false
    
    // Arrays to store newly added goals.
    @State private var addedDistanceGoals: [Goal] = []
    @State private var addedPerformanceGoals: [Goal] = []
    @State private var addedPersonalGoals: [Goal] = []
    
    // New state for the focus goal (if one is long-pressed).
    @State private var focusGoalTuple: (goal: Goal, type: GoalType)? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header remains unchanged
                    HStack {
                        Text("Goals")
                            .fontWeight(.semibold)
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.bottom, 10)
                    
                    // Goals progress box remains unchanged
                    GoalsProgressBox(progress: 0.48)
                    
                    // Use GoalTypeSelectorView here
                    GoalTypeSelectorView(selectedGoalType: $selectedGoalType)
                    
                    // Use GoalsListView here, passing the focus goal if it matches the selected type.
                    GoalsListView(
                        selectedGoalType: selectedGoalType,
                        addedDistanceGoals: addedDistanceGoals,
                        addedPerformanceGoals: addedPerformanceGoals,
                        addedPersonalGoals: addedPersonalGoals,
                        focusGoal: (focusGoalTuple?.type == selectedGoalType) ? focusGoalTuple?.goal : nil,
                        onLongPress: { goal, type in
                            withAnimation {
                                if let current = focusGoalTuple, current.goal.id == goal.id {
                                    // If already focused, remove focus
                                    focusGoalTuple = nil
                                } else {
                                    // Otherwise, set as focus
                                    focusGoalTuple = (goal, type)
                                }
                            }
                        }
                    )


                    
                    // Set New Goal Button remains unchanged
                    Button(action: { showingGoalSettingView = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Set New Goal")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                }
                .padding()
            }
            .sheet(isPresented: $showingGoalSettingView) {
                GoalsSettingView(onGoalSet: { goal, category in
                    switch category {
                    case .distance:
                        addedDistanceGoals.append(goal)
                    case .performance:
                        addedPerformanceGoals.append(goal)
                    case .personal:
                        addedPersonalGoals.append(goal)
                    }
                })
            }
            .navigationBarHidden(true)
        }
    }
}




// Goal Item Component
struct GoalItemView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let currentValue: String
    let targetValue: String
    let unit: String
    let progress: Double
    
    var body: some View {
        HStack {
            // Left side - Icon
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.trailing, 10)
            
            // Middle - Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.gray)
                    Text("\(currentValue) / \(targetValue) \(unit)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Progress bar
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(height: 6)
                        .opacity(0.2)
                        .foregroundColor(.blue)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .frame(width: CGFloat(progress) * UIScreen.main.bounds.width * 0.65, height: 6)
                        .foregroundColor(.blue)
                        .cornerRadius(3)
                }
            }
            
            Spacer()
            
            // Right side - More button
            Button(action: {
                // More options
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct GoalsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsView()
    }
}
