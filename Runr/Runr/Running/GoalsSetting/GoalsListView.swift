//
//  GoalsListView.swift
//  Runr
//
//  Created by Noah Moran on 2/4/2025.
//

import SwiftUI

struct GoalsListView: View {
    let selectedGoalType: GoalsView.GoalType
    let addedDistanceGoals: [Goal]
    let addedPerformanceGoals: [Goal]
    let addedPersonalGoals: [Goal]
    // Optional focus goal for the selected category.
    let focusGoal: Goal?
    // Closure to handle long press on a goal.
    let onLongPress: ((Goal, GoalsView.GoalType) -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            switch selectedGoalType {
            case .distance:
                // Static example(s) for Distance
                GoalItemView(
                    icon: "figure.walk.circle.fill",
                    iconColor: .blue,
                    title: "Step Count",
                    currentValue: "6,745",
                    targetValue: "12,000",
                    unit: "Steps",
                    progress: 0.56
                )
                // Reorder added goals: if a focus goal exists, show it first.
                let reordered = focusGoal != nil ? [focusGoal!] + addedDistanceGoals.filter { $0.id != focusGoal!.id } : addedDistanceGoals
                ForEach(reordered) { goal in
                    GoalItemView(
                        icon: "star.fill",
                        iconColor: .orange,
                        title: goal.title,
                        currentValue: "0",
                        targetValue: goal.target,
                        unit: "",
                        progress: 0.0
                    )
                    .overlay(
                        (focusGoal?.id == goal.id) ?
                            RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 3)
                        : nil
                    )
                    .onLongPressGesture(minimumDuration: 1.0) {
                        onLongPress?(goal, .distance)
                    }
                }
                
            case .performance:
                // Static example(s) for Performance
                GoalItemView(
                    icon: "speedometer",
                    iconColor: .blue,
                    title: "Pace Target",
                    currentValue: "6:30",
                    targetValue: "5:45",
                    unit: "min/km",
                    progress: 0.65
                )
                let reordered = focusGoal != nil ? [focusGoal!] + addedPerformanceGoals.filter { $0.id != focusGoal!.id } : addedPerformanceGoals
                ForEach(reordered) { goal in
                    GoalItemView(
                        icon: "star.fill",
                        iconColor: .orange,
                        title: goal.title,
                        currentValue: "0",
                        targetValue: goal.target,
                        unit: "",
                        progress: 0.0
                    )
                    .overlay(
                        (focusGoal?.id == goal.id) ?
                            RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 3)
                        : nil
                    )
                    .onLongPressGesture(minimumDuration: 1.0) {
                        onLongPress?(goal, .performance)
                    }
                }
                
            case .personal:
                // Static example(s) for Personal
                GoalItemView(
                    icon: "flame.fill",
                    iconColor: .blue,
                    title: "Calorie Burn Target",
                    currentValue: "172",
                    targetValue: "300",
                    unit: "kcal",
                    progress: 0.57
                )
                let reordered = focusGoal != nil ? [focusGoal!] + addedPersonalGoals.filter { $0.id != focusGoal!.id } : addedPersonalGoals
                ForEach(reordered) { goal in
                    GoalItemView(
                        icon: "star.fill",
                        iconColor: .orange,
                        title: goal.title,
                        currentValue: "0",
                        targetValue: goal.target,
                        unit: "",
                        progress: 0.0
                    )
                    .overlay(
                        (focusGoal?.id == goal.id) ?
                            RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 3)
                        : nil
                    )
                    .onLongPressGesture(minimumDuration: 1.0) {
                        onLongPress?(goal, .personal)
                    }
                }
            }
        }
    }
}

struct GoalsListView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsListView(
            selectedGoalType: .distance,
            addedDistanceGoals: [Goal(title: "Test Goal", target: "20")],
            addedPerformanceGoals: [],
            addedPersonalGoals: [],
            focusGoal: nil,
            onLongPress: nil
        )
    }
}
