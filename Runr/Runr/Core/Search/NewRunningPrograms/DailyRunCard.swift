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
    let weekIndex: Int      // The index of the week this day belongs to
    let dayIndex: Int       // Passed in from the parent view

    // Use ObservedObject for the shared view model
    @ObservedObject var viewModel: NewRunningProgramViewModel

    // Local state to reflect completion status, initialized from the model
    @State private var isCompletedLocal: Bool

    // Updated initializer
    init(daily: DailyPlan, isSelected: Bool, weekIndex: Int, dayIndex: Int, viewModel: NewRunningProgramViewModel) {
        self.daily = daily
        self.isSelected = isSelected
        self.weekIndex = weekIndex
        self.dayIndex = dayIndex
        self.viewModel = viewModel
        self._isCompletedLocal = State(initialValue: daily.isCompleted)
    }

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(daily.dailyDistance > 0 ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                Text(daily.day.prefix(1))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading) {
                Text(daily.day)
                    .font(.headline)
                if daily.dailyDistance > 0 {
                    Text("\(daily.dailyDistance, specifier: "%.1f") km run")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Rest day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Only show the button on run days
            if daily.dailyDistance > 0 {
                Button {
                    let newCompletionState = !isCompletedLocal
                    // Animate the state change (which will update the background)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isCompletedLocal = newCompletionState
                    }
                    Task {
                        await viewModel.markDailyRunCompleted(for: Date(), completed: newCompletionState)

                    }
                } label: {
                    Image(systemName: isCompletedLocal ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isCompletedLocal ? .green : .blue)
                }
                .buttonStyle(PlainButtonStyle())
                .onChange(of: daily.isCompleted) { newValue in
                    isCompletedLocal = newValue
                }
            }
        }
        .padding()
        .background(
            // The background color changes to green if the day is completed.
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isCompletedLocal ? Color.green.opacity(0.3) :
                        (isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                )
                .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
                // Animate changes in the background fill.
                .animation(.easeInOut, value: isCompletedLocal)
        )
    }
}


struct DailyRunCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleDaily = DailyPlan(day: "Monday", distance: 5.0)
        let previewViewModel = NewRunningProgramViewModel()

        DailyRunCard(
            daily: sampleDaily,
            isSelected: false,
            weekIndex: 0,
            dayIndex: 0,  // Using the provided index directly
            viewModel: previewViewModel
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
