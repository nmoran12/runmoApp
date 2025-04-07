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
    
    // Local state to track taps
    @State private var isCompletedLocal: Bool

    // Initialize the local state from your model
    init(daily: DailyPlan, isSelected: Bool) {
        self.daily = daily
        self.isSelected = isSelected
        self._isCompletedLocal = State(initialValue: daily.isCompleted)
    }

    var body: some View {
        HStack {
            // Day indicator
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
                Button(action: {
                    // Flip the local state so the icon updates
                    isCompletedLocal.toggle()
                    // Call your helper to persist if you want
                    markDailyRunCompletedHelper()
                }) {
                    Image(systemName: isCompletedLocal
                          ? "checkmark.circle.fill"
                          : "circle")
                        .font(.title2)
                        .foregroundColor(isCompletedLocal ? .green : .blue)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(isSelected ? 0.5 : 1.0)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

#Preview {
    DailyRunCard(
        daily: DailyPlan(day: "Monday", distance: 5.0),
        isSelected: false
    )
}
