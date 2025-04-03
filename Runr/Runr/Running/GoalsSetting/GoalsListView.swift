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
    // Optional focus goal for the selected category.
    let focusGoal: Goal?
    // Closure to handle long press on a goal.
    let onLongPress: ((Goal, GoalsView.GoalType) -> Void)?
    
    // State to track animation
    @State private var animatingGoalID: UUID? = nil
    
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
                    .swipeToDelete {
                            removeGoal(goal)
                        }
                    // New animation effect - fade up
                    .opacity((focusGoal?.id == goal.id) && (animatingGoalID == goal.id) ? 0.7 : 1.0)
                    .offset(y: (focusGoal?.id == goal.id) && (animatingGoalID == goal.id) ? 10 : 0)
                    .zIndex((focusGoal?.id == goal.id) ? 1 : 0)
                    .transition((focusGoal?.id == goal.id) ?
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ) : .identity
                    )
                    .id("\(goal.id)-\(focusGoal?.id == goal.id)") // Helps trigger animations
                    .onLongPressGesture(minimumDuration: 0.8) { // Reduced duration for better UX
                        // Set the animating goal ID before calling onLongPress
                        self.animatingGoalID = goal.id
                        
                        // Reset animation flag after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            self.animatingGoalID = nil
                        }
                        
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
                    .swipeToDelete {
                            removeGoal(goal)
                        }
                    // New animation effect - fade up
                                        .opacity((focusGoal?.id == goal.id) && (animatingGoalID == goal.id) ? 0.7 : 1.0)
                                        .offset(y: (focusGoal?.id == goal.id) && (animatingGoalID == goal.id) ? 10 : 0)
                                        .zIndex((focusGoal?.id == goal.id) ? 1 : 0)
                                        .transition((focusGoal?.id == goal.id) ?
                                            .asymmetric(
                                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                                removal: .opacity
                                            ) : .identity
                                        )
                                        .id("\(goal.id)-\(focusGoal?.id == goal.id)") // Helps trigger animations
                                        .onLongPressGesture(minimumDuration: 0.8) { // Reduced duration for better UX
                                            // Set the animating goal ID before calling onLongPress
                                            self.animatingGoalID = goal.id
                                            
                                            // Reset animation flag after animation completes
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                self.animatingGoalID = nil
                                            }
                                            
                                            onLongPress?(goal, .distance)
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
                    .swipeToDelete {
                            removeGoal(goal)
                        }
                    // New animation effect - fade up
                    .opacity((focusGoal?.id == goal.id) && (animatingGoalID == goal.id) ? 0.7 : 1.0)
                    .offset(y: (focusGoal?.id == goal.id) && (animatingGoalID == goal.id) ? 10 : 0)
                    .zIndex((focusGoal?.id == goal.id) ? 1 : 0)
                    .transition((focusGoal?.id == goal.id) ?
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ) : .identity
                    )
                    .id("\(goal.id)-\(focusGoal?.id == goal.id)") // Helps trigger animations
                    .onLongPressGesture(minimumDuration: 0.8) {
                        // Set the animating goal ID before calling onLongPress
                        self.animatingGoalID = goal.id
                        
                        // Reset animation flag after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            self.animatingGoalID = nil
                        }
                        
                        onLongPress?(goal, .personal)
                    }
                }
            }
        }
        .animation(.goalFocus, value: focusGoal?.id) // Animates the list when focus changes
    }
    private func removeGoal(_ goal: Goal) {
        switch selectedGoalType {
        case .distance:
            addedDistanceGoals.removeAll { $0.id == goal.id }
        case .performance:
            addedPerformanceGoals.removeAll { $0.id == goal.id }
        case .personal:
            addedPersonalGoals.removeAll { $0.id == goal.id }
        }
    }
}

struct GoalsListView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsListView(
            selectedGoalType: .distance,
            // Use .constant(...) to create a non-mutable binding for previews
            addedDistanceGoals: .constant([
                Goal(title: "Test Goal", target: "20", category: "Distance")
            ]),
            addedPerformanceGoals: .constant([]),
            addedPersonalGoals: .constant([]),
            focusGoal: nil,
            onLongPress: nil
        )
    }
}

