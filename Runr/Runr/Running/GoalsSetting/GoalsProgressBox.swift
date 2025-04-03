//
//  GoalsProgressBox.swift
//  Runr
//
//  Created by Noah Moran on 2/4/2025.
//

import SwiftUI

struct GoalsProgressBox: View {
    var progress: Double = 0.48
    var focusedGoalTitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("0 / 11km")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(focusedGoalTitle ?? "Goal Progress")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Custom progress bar to match the design
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: availableWidth * CGFloat(progress), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 343, height: 140)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(#colorLiteral(red: 0.2, green: 0.5, blue: 0.95, alpha: 1)), Color(#colorLiteral(red: 0.4, green: 0.65, blue: 1, alpha: 1))]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    GoalsProgressBox()
}

