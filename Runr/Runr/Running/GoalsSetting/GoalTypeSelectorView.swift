//
//  GoalTypeSelectorView.swift
//  Runr
//
//  Created by Noah Moran on 2/4/2025.
//

import SwiftUI

struct GoalTypeSelectorView: View {
    @Binding var selectedGoalType: GoalsView.GoalType

    var body: some View {
        HStack(spacing: 10) {
            ForEach(GoalsView.GoalType.allCases, id: \.self) { type in
                Button(action: {
                    selectedGoalType = type
                }) {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedGoalType == type ? Color.black : Color.white)
                                .overlay(
                                    Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(selectedGoalType == type ? .white : .primary)
                }
            }
        }
        .padding(.vertical, 5)
    }
}

struct GoalTypeSelectorView_Previews: PreviewProvider {
    @State static var selectedType: GoalsView.GoalType = .distance
    static var previews: some View {
        GoalTypeSelectorView(selectedGoalType: $selectedType)
    }
}

