//
//  ShowCurrentCompletedView.swift
//  Runr
//
//  Created by Noah Moran on 17/4/2025.
//

import SwiftUI

/// A view that displays today's run plan and, upon completion, shows the actual run stats.
struct ShowCurrentCompletedView: View {
    @EnvironmentObject private var viewModel: NewRunningProgramViewModel

    var body: some View {
        Group {
            if let plan = viewModel.getTodaysDailyPlan() {
                // If the plan is completed and we have run data, show the completed view
                if plan.isCompleted, let runData = viewModel.todaysRunData {
                    DailyRunCompletedView(daily: plan, runData: runData)
                } else {
                    // Otherwise show the plan and a button to start or mark complete
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today: \(plan.day)")
                            .font(.title)
                            .bold()
                        Text(plan.dailyRunType ?? "Run")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(String(format: "Distance: %.1f km", plan.dailyDistance))
                            .font(.headline)

                        Button(action: {
                            Task {
                                // load today’s run, then mark complete
                                await viewModel.loadTodaysRunData()
                                await viewModel.markDailyRunCompleted(completed: true)
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text("Mark as Complete")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.secondarySystemBackground)))
                }
            } else {
                Text("No run scheduled for today.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .onAppear {
            Task { await viewModel.loadTodaysRunData() }
        }
    }
}
