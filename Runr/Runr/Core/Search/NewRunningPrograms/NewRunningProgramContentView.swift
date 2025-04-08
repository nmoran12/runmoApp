//
//  NewRunningProgramContentView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct NewRunningProgramContentView: View {
    // Use @StateObject here as this view likely "owns" the VM for this specific program instance
    @StateObject private var viewModel = NewRunningProgramViewModel()
    let plan: NewRunningProgram // The program data is passed into this view

    var body: some View {
        // Consider if NavigationView is needed here or if it's part of a larger navigation structure
        NavigationView { // Removed for now, add back if needed
            ScrollView {
                VStack(spacing: 0) { // Use VStack with spacing 0, let cards handle padding
                    
                    // Display the NewRunningProgramCardView (summary card)
                    NewRunningProgramCardView(program: plan)
                        .padding(.horizontal)
                        .padding(.bottom) // Add some bottom padding
                    
                    
                    Text("Weekly Breakdown") // Add a section header
                        .font(.title2).bold()
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                    
                    // --- MODIFIED ForEach ---
                    ForEach(Array(plan.weeklyPlan.enumerated()), id: \.element.id) { index, singleWeek in
                        WeeklyPlanCardView(
                            plan: singleWeek,
                            weekIndex: index,   // <-- Pass the index
                            viewModel: viewModel // <-- Pass the viewModel
                        )
                        .padding(.horizontal) // Add horizontal padding to cards
                        .padding(.bottom)    // Add vertical spacing between cards
                    }
                    // --- END MODIFICATION ---
                    
                    
                    // TEMPORARY Upload Button (Consider moving this elsewhere, e.g., when saving edits)
                    Button(action: {
                        // This now uses the STABLE ID based on the title for saving/updating
                        // Ensure the 'plan' object passed in has the correct title
                        Task { // Use Task for async operation
                            await viewModel.saveNewRunningProgram(plan) // Use the correct save function
                        }
                    }) {
                        Text("Save/Upload Program") // Changed text for clarity
                            .padding()
                            .frame(maxWidth: .infinity) // Make button wider
                            .background(Color.green) // Use green for save?
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding() // Padding around the button
                }
            }
        }
            .navigationTitle(plan.title) // Set title from the program
            .navigationBarTitleDisplayMode(.inline)
             // Load the program into the ViewModel when this view appears
             // This assumes the plan passed in IS the one you want to manage/update

        .onAppear {
            // --- Call the ViewModel's load function ---
            // Pass the title of the program this view is meant to display
            Task {
                await viewModel.loadProgram(titled: plan.title)
            }
            print("Program Content View appeared. Attempting to load program: \(plan.title)")
        }
             .background(Color(.systemGroupedBackground).ignoresSafeArea()) // Set background
        // } // End NavigationView
    }
}

