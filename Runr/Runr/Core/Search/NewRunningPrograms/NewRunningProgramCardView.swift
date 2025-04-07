//
//  NewRunningProgramCardView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct NewRunningProgramCardView: View {
    
    let program: NewRunningProgram
    // For now, weeksCompleted is hard-coded to 0
    let weeksCompleted: Int = 0
    
    // Compute the total distance from all weeks dynamically
    var totalDistanceFromWeeks: Double {
         program.weeklyPlan.reduce(0) { $0 + $1.weeklyTotalDistance }
    }
    
    var body: some View {
        // Plan card
        VStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        // Display the program title
                        Text(program.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Display race info if available
                        if let race = program.raceName {
                            HStack(spacing: 2) {
                                Text("Your Race:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(race)
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        HStack(spacing: 2) {
                            Text("Your Race Date:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("OCT 13, 2024")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 36, height: 44)
                            .cornerRadius(6)
                        
                        Text("13.1")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                // Progress bar using totalWeeks from the program
                HStack(spacing: 4) {
                    ForEach(0..<program.totalWeeks, id: \.self) { i in
                        Rectangle()
                            .fill(i < weeksCompleted ? Color.green : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
                .padding(.vertical, 8)
                
                HStack {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.orange)
                        
                        Text("Weeks completed")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Distance")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "figure.run")
                        .foregroundColor(.orange)
                }
                
                // Use computed values for weeks and distance progress
                HStack {
                    Text("\(weeksCompleted)/\(program.totalWeeks)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Here "0" represents distance completed; update that as needed.
                    Text("0/\(Int(totalDistanceFromWeeks)) km")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    NewRunningProgramCardView(program: sampleProgram)
}
