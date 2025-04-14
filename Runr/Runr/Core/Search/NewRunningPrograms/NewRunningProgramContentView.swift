//
//  NewRunningProgramContentView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct NewRunningProgramContentView: View {
    // This view "owns" the view model for this program instance.
    @EnvironmentObject private var viewModel: NewRunningProgramViewModel
    let plan: NewRunningProgram // The program template is passed into this view
    
    let beginnerProgram = BeginnerTemplates.createBeginnerProgram(sampleWeeklyPlans: sampleWeeklyPlans)
    let intermediateProgram = IntermediateTemplates.createIntermediateProgram(allWeeks: allWeeks)
    
    /// Use the program loaded from Firestore if available.
        var displayedProgram: NewRunningProgram {
            viewModel.currentProgram ?? plan
        }


    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    
                    // Use displayedProgram instead of plan
                    NewRunningProgramCardView(program: displayedProgram)
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                    // For a marathon target, for example, insert the estimated time view here:
                   // EstimatedRunTimeView(targetDistance: 42.2)
                          //  .padding(.horizontal)
                          //  .padding(.bottom)
                    
                    Spacer()
                    Spacer()
                    
                    ZStack(alignment: .leading) {
                        Text("Todays Run")
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // This forces the container to use full width.
                    .padding(.horizontal)
                    
                    // Current Day Plan View
                    ShowCurrentDayPlanView()
                        .environmentObject(viewModel) // Ensure the view model is passed properly.
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    
                    ZStack(alignment: .leading) {
                        Text("Weekly Plans")
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // This forces the container to use full width.
                    .padding(.horizontal)

                    
                    // Determine which weekly plan to display:
                    // If there's an active user program, use its weeklyPlan; otherwise, use the template.
                    // new might have to remove
                    // For weekly plans, merge the updated user data with the template's weekly plans:
                                        let displayedWeeklyPlan = mergeWeeklyPlans(
                                            template: displayedProgram.weeklyPlan,
                                            user: viewModel.currentUserProgram?.weeklyPlan
                                        )

                    
                    ForEach(Array(displayedWeeklyPlan.enumerated()), id: \.element.id) { index, singleWeek in
                                            WeeklyPlanCardView(
                                                plan: singleWeek,
                                                weekIndex: index,
                                                viewModel: _viewModel
                                            )
                                            .padding(.horizontal)
                                            .padding(.bottom)
                                        }
                    
                    Button("Update Sample Running Program") {
                        Task {
                            await updateSampleRunningProgram()
                        }
                    }

                    
                    Button("Update Beginner Marathon Template") {
                                Task {
                                    await BeginnerTemplates.updateBeginnerMarathonTemplate(using: beginnerProgram)
                                }
                            }
                            .padding()
                    
                    // NEW: Update Intermediate Marathon Template Button
                    Button("Update Intermediate Marathon Template") {
                        Task {
                            await IntermediateTemplates.updateIntermediateMarathonTemplate(using: intermediateProgram)
                        }
                    }
                    .padding()
                    
                    // DO NOT REMOVE
                     //seeding running program template only click once
                    Button("Seed Running Program Template") {
                        Task {
                            do {
                                // Use your sample program or a specific template you want to seed.
                                try await seedAllRunningProgramTemplates()
                            } catch {
                                print("Error seeding template: \(error.localizedDescription)")
                            }
                        }
                    }

                    
                    // Display a message if an active program is found.
                                        if viewModel.hasActiveProgram {
                                            Text("You already have an active running program.")
                                                .foregroundColor(.red)
                                                .padding()
                                        }
                                        
                                        // The "Start Program" button now creates a user instance.
                                        Button(action: {
                                            Task {
                                                // Retrieve the user's username from AuthService.
                                                let currentUsername = AuthService.shared.currentUser?.username ?? "UnknownUser"
                                                
                                                // Before starting, check if the user already has an active program.
                                                await viewModel.checkActiveUserProgram(for: currentUsername)
                                                
                                                // Only start a new program if none is active.
                                                if !viewModel.hasActiveProgram {
                                                    await viewModel.startUserRunningProgram(from: plan, username: currentUsername)
                                                    // After creating a user instance, update the check.
                                                    await viewModel.checkActiveUserProgram(for: currentUsername)
                                                }
                                            }
                                        }) {
                                            Text("Start Program")
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(viewModel.hasActiveProgram ? Color.gray : Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                        // Disable the button if an active program exists.
                                        .disabled(viewModel.hasActiveProgram)
                                        .padding()
                                    }
                                }
                            }
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                // Load the template as before.
                await viewModel.loadProgram(titled: plan.title)
                let currentUsername = AuthService.shared.currentUser?.username ?? "UnknownUser"
                await viewModel.checkActiveUserProgram(for: currentUsername)
                if viewModel.hasActiveProgram {
                    // Load the active user instance.
                    await viewModel.loadActiveUserProgram(for: currentUsername)
                }
            }
            print("Program Content View appeared. Attempting to load program: \(plan.title)")
        }

        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Update Intermediate Marathon Template Function

/// Creates and updates the Intermediate Marathon Running Program based on a sample template structure.
/// The intermediate program uses similar structure as the sample but with updated values.
@MainActor
func updateIntermediateMarathonTemplate() async {
    // Define the intermediate program using values specific to intermediate runners.
    let intermediateProgram = NewRunningProgram(
        id: UUID(),
        title: "Intermediate Marathon Running Program",
        raceName: "City Marathon 2025",
        subtitle: "For runners looking to improve performance",
        finishDate: Date().addingTimeInterval(60 * 60 * 24 * 150), // e.g., 150 days from now
        imageUrl: "https://via.placeholder.com/300?text=Intermediate",
        totalDistance: 500,
        planOverview: """
            This intermediate training program builds upon the sample running program template.
            It is designed for runners who already have a base level of fitness and now want to
            improve performance with additional speed, endurance, and strength workouts.
            """,
        experienceLevel: "Intermediate",
        // Reuse the same weekly plan template from the sample program.
        weeklyPlan: allWeeks
    )
    
    do {
        try await updateTemplate(intermediateProgram)
        print("Template 'intermediate-marathon-running-program' updated successfully.")
    } catch {
        print("Error updating intermediate marathon template: \(error.localizedDescription)")
    }
}
