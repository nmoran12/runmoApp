//
//  GoalRowView.swift
//  Runr
//
//  Created by Noah Moran on 7/4/2025.
//

import SwiftUI

struct GoalRowView: View {
    // Input properties needed by the row
    let goal: Goal
    let goalType: GoalsView.GoalType // Pass the type for onLongPress
    let focusGoal: Goal?
    let animatingGoalID: String? // Use String? as corrected previously
    let onLongPress: ((Goal, GoalsView.GoalType) -> Void)?
    let onDelete: (Goal) -> Void

    // Determine icon/color based on goal properties (copied from GoalItemView for now)
     var icon: String {
         switch goal.category {
             case "Distance": return "ruler.fill"
             case "Time": return "clock.fill"
             case "Performance": return "speedometer"
             default: return "target"
         }
     }
     var iconColor: Color {
         goal.isCompleted ? .green : .orange // Use Goal properties now
     }


    var body: some View {
        // Use the GoalItemView configured with the real goal data
        GoalItemView(goal: goal) // Pass the goal object
            .overlay(
                // Apply focus highlight if this goal is the focus goal
                (focusGoal?.id == goal.id) ?
                    RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 3)
                : nil
            )
            .swipeToDelete {
                onDelete(goal) // Call the delete closure
            }
            // Apply animation effects based on focus and animation state
            .opacity((focusGoal?.id == goal.id) && (animatingGoalID == goal.id) ? 0.7 : 1.0)
            .offset(y: (focusGoal?.id == goal.id) && (animatingGoalID == goal.id) ? 10 : 0)
            .zIndex((focusGoal?.id == goal.id) ? 1 : 0) // Bring focused item to front
            .transition((focusGoal?.id == goal.id) ?
                .asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity
                ) : .identity
            )
             // Use goal.id directly, ensuring it's stable. Combining might be unnecessary complexity.
            .id(goal.id)
            .onLongPressGesture(minimumDuration: 0.8) {
                 // Call the onLongPress closure, passing the goal and its type
                 onLongPress?(goal, goalType)
                 // Note: The animation triggering (setting animatingGoalID) should ideally happen
                 // within the onLongPress handler in the parent view (GoalsView) for cleaner state management,
                 // but keeping it here is closer to your original logic for now.
             }
    }
}

// Modify GoalItemView to accept a Goal object directly
struct GoalItemView: View {
     let goal: Goal // Accept the whole goal

     // Determine icon/color based on goal properties
     var icon: String {
         switch goal.category {
             case "Distance": return "ruler.fill"
             case "Time": return "clock.fill"
             case "Performance": return "speedometer"
             default: return "target"
         }
     }
     var iconColor: Color {
         goal.isCompleted ? .green : .blue // Use Goal properties now
     }
      var checkmarkIcon: String {
          goal.isCompleted ? "checkmark.circle.fill" : "checkmark.circle"
      }
      var checkmarkColor: Color {
          goal.isCompleted ? .green : .gray
      }
      var progressBarColor: Color {
          goal.isCompleted ? .green : .blue
      }


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
                 Text(goal.title)
                     .font(.headline)
                     .strikethrough(goal.isCompleted, color: .gray) // Strike through if completed

                 HStack {
                      Image(systemName: checkmarkIcon) // Dynamic checkmark
                          .foregroundColor(checkmarkColor)
                      // Use computed properties from Goal struct
                      Text("\(goal.displayProgress) / \(goal.displayTarget) \(goal.targetUnit)")
                           .font(.subheadline)
                           .foregroundColor(.gray)
                  }


                 // Progress bar
                  GeometryReader { geometry in
                      ZStack(alignment: .leading) {
                          Rectangle()
                              .frame(height: 6)
                              .opacity(0.2)
                              .foregroundColor(progressBarColor)
                              .cornerRadius(3)

                          Rectangle()
                              .frame(width: geometry.size.width * CGFloat(goal.progressFraction), height: 6) // Use computed fraction
                              .foregroundColor(progressBarColor)
                              .cornerRadius(3)
                              .animation(.easeInOut, value: goal.progressFraction) // Animate progress
                      }
                  }
                  .frame(height: 6)
             }

             Spacer()

             // Right side - More button (optional)
             // Button(action: { /* ... */ }) { Image(systemName: "ellipsis").foregroundColor(.gray) }
         }
          // Modifiers applied to HStack if needed (e.g., padding, background)
          // These might be handled by the parent (GoalRowView or SectionContainer)
          // .padding()
          // .background(Color(.secondarySystemGroupedBackground))
          // .cornerRadius(12)
          // .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
          .opacity(goal.isCompleted ? 0.7 : 1.0) // Dim if completed
     }
 }
