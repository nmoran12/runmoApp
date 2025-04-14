//
//  RunnerExperienceSelectionView.swift
//  Runr
//
//  Created by Noah Moran on 10/4/2025.
//

import SwiftUI

struct RunnerExperienceSelectionView: View {
    let beginnerProgram = BeginnerTemplates.createBeginnerProgram(sampleWeeklyPlans: sampleWeeklyPlans)
    let intermediateProgram = IntermediateTemplates.createIntermediateProgram(allWeeks: allWeeks)
    
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Your Experience Level")
                .font(.headline)
            
            NavigationLink(destination: NewRunningProgramContentView(plan: beginnerProgram)
                    .environmentObject(NewRunningProgramViewModel())) {
                Text("Beginner Runner")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            NavigationLink(destination: NewRunningProgramContentView(plan: intermediateProgram)
                    .environmentObject(NewRunningProgramViewModel())) {
                Text("Intermediate Runner")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            
            NavigationLink(destination: NewRunningProgramContentView(plan: advancedProgram)
                    .environmentObject(NewRunningProgramViewModel())) {
                Text("Advanced Runner")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Runner Experience")
    }
}

struct RunnerExperienceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RunnerExperienceSelectionView()
        }
    }
}
