//
//  NewRunningProgramContentView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct NewRunningProgramContentView: View {
    let plan: NewRunningProgram
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                // Display the NewRunningProgramCardView (summary card)
                NewRunningProgramCardView(program: plan)
                    .padding(.horizontal)

                
                // Show each week in the program
                    ForEach(plan.weeklyPlan) { singleWeek in
                        WeeklyPlanCardView(plan: singleWeek)
                            .padding()
                    }
                
                    // TEMPORARY
                    // Upload button to send data to Firestore
                    Button(action: {
                        // This will upload your running program to Firestore
                        saveRunningProgram(plan)
                    }) {
                        Text("Upload Running Program")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                }
            .navigationBarTitle("Weekly Plan", displayMode: .inline)
        }
    }
}
