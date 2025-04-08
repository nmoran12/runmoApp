//
//  DailyRunCard.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct DailyRunCard: View {
    let daily: DailyPlan
    let isSelected: Bool
    let weekIndex: Int // --- NEW: Need the index of the week this day belongs to ---
    let dayIndex: Int // <-- Add dayIndex property

    // --- CHANGE: Use ObservedObject for the SHARED ViewModel ---
    @ObservedObject var viewModel: NewRunningProgramViewModel

    // Local state to reflect completion status, initialized from the model
    @State private var isCompletedLocal: Bool

    // Update init to accept ViewModel and weekIndex
    init(daily: DailyPlan, isSelected: Bool, weekIndex: Int, dayIndex: Int, viewModel: NewRunningProgramViewModel) {
        self.daily = daily
        self.isSelected = isSelected
        self.weekIndex = weekIndex
        self.dayIndex = dayIndex
        self.viewModel = viewModel
        // Initialize local state based on the plan passed in
        self._isCompletedLocal = State(initialValue: daily.isCompleted)
    }

    var body: some View {
        HStack {
            // ... (Your existing Day indicator, Text VStacks) ...
             ZStack {
                  Circle()
                      .fill(daily.dailyDistance > 0 ? Color.blue : Color.gray.opacity(0.3))
                      .frame(width: 40, height: 40)
                  Text(daily.day.prefix(1))
                      .font(.system(size: 16, weight: .bold))
                      .foregroundColor(.white)
             }

             VStack(alignment: .leading) {
                  Text(daily.day).font(.headline)
                  if daily.dailyDistance > 0 {
                      Text("\(daily.dailyDistance, specifier: "%.1f") km run")
                           .font(.subheadline).foregroundColor(.secondary)
                  } else {
                      Text("Rest day").font(.subheadline).foregroundColor(.secondary)
                  }
             }
             .padding(.leading, 8)


            Spacer()

            // Only show the button on run days
            if daily.dailyDistance > 0 {
                Button {
                    // --- UPDATE: Call the revised ViewModel function ---
                    let newCompletionState = !isCompletedLocal // Toggle state

                    // Update local state immediately for UI responsiveness
                    isCompletedLocal = newCompletionState

                    // Find the index of this specific day within its week's dailyPlans
                    // This assumes the daily plans array order is stable
                    if let dayIndex = viewModel.currentProgram?.weeklyPlan[weekIndex].dailyPlans.firstIndex(where: { $0.id == daily.id }) {
                        Task {
                            // Call the async function to update Firestore
                            await viewModel.markDailyRunCompleted(
                                weekIndex: weekIndex,
                                dayIndex: dayIndex,
                                completed: newCompletionState
                            )
                        }
                    } else {
                         print("Error in DailyRunCard: Could not find dayIndex for \(daily.day)")
                     }
                    // --- END UPDATE ---
                } label: {
                    Image(systemName: isCompletedLocal ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isCompletedLocal ? .green : .blue)
                }
                .buttonStyle(PlainButtonStyle())
                 // Update appearance based on local state
                 .onChange(of: daily.isCompleted) { newValue in
                      // Sync local state if the underlying model changes (e.g., from Firestore listener)
                      isCompletedLocal = newValue
                  }
            }
        }
        .padding()
        .background(
             RoundedRectangle(cornerRadius: 12)
                 .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground)) // Use adaptive background
                 .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
         )
         // Removed scaleEffect for simplicity, add back if desired
    }
}

struct DailyRunCard_Previews: PreviewProvider {
    static var previews: some View {
         let sampleDaily = DailyPlan(day: "Monday", distance: 5.0)
         let previewViewModel = NewRunningProgramViewModel()

         DailyRunCard(
             daily: sampleDaily,
             isSelected: false,
             weekIndex: 0, dayIndex: 1, // Sample index
             viewModel: previewViewModel // Dummy VM
         )
         .padding()
         .previewLayout(.sizeThatFits)
    }
}
