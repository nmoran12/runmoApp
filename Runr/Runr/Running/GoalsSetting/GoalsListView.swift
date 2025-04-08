//
//  GoalsListView.swift
//  Runr
//
//  Created by Noah Moran on 2/4/2025.
//

import SwiftUI

// Animation extension
extension Animation {
    static var goalFocus: Animation {
        .easeInOut(duration: 0.4) // Changed to a smoother ease-in-out animation
    }
}

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
    let onLongPress: ((Goal, GoalsView.GoalType) -> Void)?

    // Change animatingGoalID to String? to match Goal.id
    @State private var animatingGoalID: String? = nil

    // Computed property for the currently relevant goals array based on selected type
    private var currentGoals: [Goal] {
        switch selectedGoalType {
        case .distance: return addedDistanceGoals
        case .performance: return addedPerformanceGoals
        case .personal: return addedPersonalGoals
        }
    }

    // Computed property to reorder goals with focus goal first
    private var reorderedGoals: [Goal] {
        // Make sure focusGoal actually belongs to the current list before prepending
        guard let focus = focusGoal, currentGoals.contains(where: { $0.id == focus.id }) else {
            return currentGoals
        }
        return [focus] + currentGoals.filter { $0.id != focus.id }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Static Examples (Keep or remove as needed)
            // You might want to make these dynamic too or remove them eventually
            switch selectedGoalType {
            case .distance:
                // You might want to pass a static Goal object here instead
                 StaticGoalItemViewExample( /* Pass static data */ )
            case .performance:
                 StaticGoalItemViewExample( /* Pass static data */ )
            case .personal:
                 StaticGoalItemViewExample( /* Pass static data */ )
            }


            // --- Use ForEach with the new GoalRowView ---
            ForEach(reorderedGoals) { goal in // Iterate over the computed reorderedGoals
                GoalRowView( // Use the extracted view
                    goal: goal,
                    goalType: selectedGoalType, // Pass the current selected type
                    focusGoal: self.focusGoal, // Pass the overall focusGoal state
                    animatingGoalID: self.animatingGoalID, // Pass the animation state
                    onLongPress: self.onLongPress, // Pass the long press handler closure
                    onDelete: removeGoal // Pass the removeGoal function
                )
            }
        }
        // Keep the animation modifier for the whole VStack if needed
        .animation(.goalFocus, value: focusGoal?.id)
    }

    // removeGoal function remains the same
    private func removeGoal(_ goal: Goal) {
         // Note: Consider adding deletion from Firestore here as well
        switch selectedGoalType {
        case .distance:
            addedDistanceGoals.removeAll { $0.id == goal.id }
        case .performance:
            addedPerformanceGoals.removeAll { $0.id == goal.id }
        case .personal:
            addedPersonalGoals.removeAll { $0.id == goal.id }
        }
         // If the removed goal was the focus goal, clear the focus
         if focusGoal?.id == goal.id {
             // You might need to communicate this back to GoalsView if focusGoalTuple is there
             // Or handle focus clearing within the onLongPress logic in GoalsView
         }
     }

     // Placeholder for static examples if you keep them separate
      struct StaticGoalItemViewExample: View {
          // Add properties for static data
          var body: some View {
              // Simplified GoalItemView or specific layout for static examples
              Text("Static Example Goal")
                  .padding()
                  .background(Color.gray.opacity(0.1))
                  .cornerRadius(12)
          }
      }
}
