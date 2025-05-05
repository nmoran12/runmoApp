//
//  NewRunningProgramContentView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI

struct NewRunningProgramContentView: View {
    @EnvironmentObject private var viewModel: NewRunningProgramViewModel
    let plan: NewRunningProgram

    let beginnerProgram = BeginnerTemplates.createBeginnerProgram(sampleWeeklyPlans: sampleWeeklyPlans)
    let intermediateProgram = IntermediateTemplates.createIntermediateProgram(allWeeks: allWeeks)

    // Use the program loaded from Firestore if available.
    var displayedProgram: NewRunningProgram {
        viewModel.currentProgram ?? plan
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Overview card
                NewRunningProgramCardView(program: displayedProgram)
                    .padding(.horizontal)

                // Today's Run header
                ZStack(alignment: .leading) {
                    Text("Todays Run")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Current Day Plan
                ShowCurrentDayPlanView()
                    .environmentObject(viewModel)
                    .padding(.horizontal)
                    .padding(.bottom, 32)

                // Weekly Plans header
                ZStack(alignment: .leading) {
                    Text("Weekly Plans")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Display weekly plans
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

                // Action buttons for seeding, changing running programs, etc.
                Button("Update Sample Running Program") {
                    Task { await updateSampleRunningProgram() }
                }

                Button("Update Beginner Marathon Template") {
                    Task { await BeginnerTemplates.updateBeginnerMarathonTemplate(using: beginnerProgram) }
                }
                .padding()

                Button("Update Intermediate Marathon Template") {
                    Task { await IntermediateTemplates.updateIntermediateMarathonTemplate(using: intermediateProgram) }
                }
                .padding()

                Button("Reset Running Program") {
                    Task {
                        let currentUsername = AuthService.shared.currentUser?.username ?? "UnknownUser"
                        await viewModel.resetUserProgram(
                            using: intermediateProgram,
                            username: currentUsername
                        )
                    }
                }
                .padding()

                Button("Seed Running Program Template") {
                    Task {
                        do {
                            try await seedAllRunningProgramTemplates()
                        } catch {
                            print("Error seeding template: \(error.localizedDescription)")
                        }
                    }
                }

                if viewModel.hasActiveProgram {
                    Text("You already have an active running program.")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Leave space at bottom of scroll
            }
            .padding(.bottom, 80)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                Button(action: {
                    Task {
                        let currentUsername = AuthService.shared.currentUser?.username ?? "UnknownUser"
                        await viewModel.checkActiveUserProgram(for: currentUsername)
                        if !viewModel.hasActiveProgram {
                            await viewModel.startUserRunningProgram(from: plan, username: currentUsername)
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
                .disabled(viewModel.hasActiveProgram)
                .padding(.horizontal)
                .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 16)
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadProgram(titled: plan.title)
                let currentUsername = AuthService.shared.currentUser?.username ?? "UnknownUser"
                await viewModel.checkActiveUserProgram(for: currentUsername)
                if viewModel.hasActiveProgram {
                    await viewModel.loadActiveUserProgram(for: currentUsername)
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

// MARK: - Update Intermediate Marathon Template Function

@MainActor
func updateIntermediateMarathonTemplate() async {
    let intermediateProgram = NewRunningProgram(
        id: UUID(),
        title: "Intermediate Marathon Running Program",
        raceName: "City Marathon 2025",
        subtitle: "For runners looking to improve performance",
        finishDate: Date().addingTimeInterval(60 * 60 * 24 * 150),
        imageUrl: "https://via.placeholder.com/300?text=Intermediate",
        totalDistance: 500,
        planOverview: """
            This intermediate training program builds upon the sample running program template.
            It is designed for runners who already have a base level of fitness and now want to
            improve performance with additional speed, endurance, and strength workouts.
            """,
        experienceLevel: "Intermediate",
        weeklyPlan: allWeeks
    )

    do {
        try await updateTemplate(intermediateProgram)
        print("Template 'intermediate-marathon-running-program' updated successfully.")
    } catch {
        print("Error updating intermediate marathon template: \(error.localizedDescription)")
    }
}
