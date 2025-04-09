//
//  NewRunningProgramCardView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct NewRunningProgramCardView: View {
    
    let program: NewRunningProgram
    @EnvironmentObject var programVM: NewRunningProgramViewModel

    var weeksCompleted: Int {
        if let userProgram = programVM.currentUserProgram {
            // Define a completed week as one where all daily plans are completed.
            return userProgram.weeklyPlan.filter { week in
                week.dailyPlans.allSatisfy { $0.isCompleted }
            }.count
        }
        return 0
    }
    
    // Compute the total distance from all weeks dynamically
    var totalDistanceFromWeeks: Double {
         program.weeklyPlan.reduce(0) { $0 + $1.weeklyTotalDistance }
    }

    // A helper to format the target race time (in seconds) as a time string.
    private func formatTime(from seconds: Double) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d:%02d", hrs, mins, secs)
    }
    
    var body: some View {
        // Plan card
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 16) {
                // Header section
                HStack(alignment: .top) {
                    // Program title
                    Text(program.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Race distance badge
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
                
                // Race details without labels
                VStack(alignment: .leading, spacing: 6) {
                    if let race = program.raceName {
                        Text(race)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    
                    Text("OCT 13, 2024")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                .padding(.vertical, 4)
                
                // Stats row
                HStack {
                    // Weeks completed
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                            
                            Text("Weeks completed")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(weeksCompleted)/\(program.totalWeeks)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    // Target race time
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            
                            Text("Target Race Time")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(formatTime(from: programVM.currentUserProgram?.targetTimeSeconds ?? programVM.targetTimeSeconds))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    NewRunningProgramCardView(program: sampleProgram)
        .environmentObject(NewRunningProgramViewModel())
}
