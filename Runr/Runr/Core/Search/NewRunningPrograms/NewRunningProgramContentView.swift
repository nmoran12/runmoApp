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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Display a summary card of the running program template
                    NewRunningProgramCardView(program: plan)
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                    // For a marathon target, for example, insert the estimated time view here:
                   // EstimatedRunTimeView(targetDistance: 42.2)
                          //  .padding(.horizontal)
                          //  .padding(.bottom)
                    
                    // NEW: Current Day Plan View
                    ShowCurrentDayPlanView()
                        .environmentObject(viewModel) // Ensure the view model is passed properly.
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    Text("Weekly Breakdown")
                        .font(.title2).bold()
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                    
                    // Determine which weekly plan to display:
                    // If there's an active user program, use its weeklyPlan; otherwise, use the template.
                    // new might have to remove
                    let displayedWeeklyPlan = mergeWeeklyPlans(template: plan.weeklyPlan,
                                                                 user: viewModel.currentUserProgram?.weeklyPlan)

                    
                    ForEach(Array(displayedWeeklyPlan.enumerated()), id: \.element.id) { index, singleWeek in
                        WeeklyPlanCardView(
                            plan: singleWeek,
                            weekIndex: index,
                            viewModel: _viewModel
                        )
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    
                    // DO NOT REMOVE
                     //seeding running program template only click once
                    Button("Seed Running Program Template") {
                        Task {
                            do {
                                // Use your sample program or a specific template you want to seed.
                                try await seedTemplateIfNeeded(sampleProgram)
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

