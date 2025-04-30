//
//  GoalsListView.swift
//  Runr
//
//  Created by Noah Moran on 2/4/2025.
//

import SwiftUI

// Smooth focus animation
extension Animation {
    static var goalFocus: Animation {
        .easeInOut(duration: 0.4)
    }
}

// Reusable swipe-to-delete modifier
extension View {
    func swipeToDelete(removeAction: @escaping () -> Void) -> some View {
        self.swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: removeAction) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct GoalsListView: View {
    let selectedGoalType: GoalsView.GoalType
    @Binding var addedDistanceGoals: [Goal]
    @Binding var addedPerformanceGoals: [Goal]
    @Binding var addedPersonalGoals: [Goal]
    let focusGoal: Goal?
    let onLongPress: (Goal, GoalsView.GoalType) -> Void

    @State private var animatingGoalID: String? = nil

    // Pick the right array based on the current segment
    private var currentGoals: [Goal] {
        switch selectedGoalType {
        case .distance:    return addedDistanceGoals
        case .performance: return addedPerformanceGoals
        case .personal:    return addedPersonalGoals
        }
    }

    // If a goal is “focused,” it floats to the top
    private var reorderedGoals: [Goal] {
        guard let focus = focusGoal,
              currentGoals.contains(where: { $0.id == focus.id }) else {
            return currentGoals
        }
        return [focus] + currentGoals.filter { $0.id != focus.id }
    }

    var body: some View {
        VStack(spacing: 16) {
            // (Optional) Your static example slot
            switch selectedGoalType {
            case .distance:
                StaticGoalItemViewExample()
            case .performance:
                StaticGoalItemViewExample()
            case .personal:
                StaticGoalItemViewExample()
            }

            // Dynamic list of real goals
            ForEach(reorderedGoals) { goal in
                GoalRowView(
                    goal: goal,
                    goalType: selectedGoalType,
                    focusGoal: focusGoal,
                    animatingGoalID: animatingGoalID,
                    onLongPress: onLongPress,
                    onDelete: { goalItem in
                        handleDelete(goalItem)
                    }
                )
                .swipeToDelete {
                    handleDelete(goal)
                }
            }

        }
        .animation(.goalFocus, value: focusGoal?.id)
    }

    /// 1. Deletes in Firestore  2. Removes from the local array so the UI updates instantly
    private func handleDelete(_ goal: Goal) {
        Task {
            do {
                try await GoalsService.shared.deleteUserGoal(goal.id)
                print("Deleted goal \(goal.id)")
            } catch {
                print("Failed to delete goal:", error)
            }
        }
        removeGoal(goal)
    }

    /// Just peels off the deleted goal from the proper binding
    private func removeGoal(_ goal: Goal) {
        switch selectedGoalType {
        case .distance:
            addedDistanceGoals.removeAll    { $0.id == goal.id }
        case .performance:
            addedPerformanceGoals.removeAll { $0.id == goal.id }
        case .personal:
            addedPersonalGoals.removeAll    { $0.id == goal.id }
        }
    }
}

// Simple placeholder for your static examples
struct StaticGoalItemViewExample: View {
    var body: some View {
        Text("Static Example Goal")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}
