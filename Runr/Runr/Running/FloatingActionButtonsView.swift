//
//  FloatingActionButtonsView.swift
//  Runr
//
//  Created by Noah Moran on 31/3/2025.
//

import SwiftUI

struct FloatingActionButtonsView: View {
    @Binding var isRunning: Bool
    @Binding var showPostRunDetails: Bool
    @Binding var selectedFootwear: String
    @ObservedObject var ghostRunnerManager: GhostRunnerManager
    
    @State private var runs: [RunData] = []
    @State private var showCalendarView = false
    @State private var showGoalsView = false
    @State private var showGhostRunnerSelection = false  // New state variable
    
    /// Action to perform when the calendar button is tapped.
    var calendarAction: () -> Void
    /// Action to perform when the goal setting button is tapped.
    var goalsAction: () -> Void
    /// Action to perform when the ghost runner button is tapped.
    var ghostRunnerAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Calendar button always shown.
            CalendarButtonView {
                            Task {
                                await refreshRuns()  // fetch updated runs
                                showCalendarView = true
                            }
                        }
                    .sheet(isPresented: $showCalendarView) {
                        CalendarView(runs: runs)
                    }
                    .task {
                        await refreshRuns() // load initial runs data if needed
                    }
            
            
            // Goals button always shown.
            GoalsButtonView {
                // Set the state to show GoalsView when the button is tapped.
                showGoalsView = true
                // Optionally, if you want to also perform additional actions:
                //goalsAction()
            }
            
            // Ghost Runner button always shown.
            GhostRunButtonView(
                action: {
                    // Set state to show ghost runner selection view.
                    showGhostRunnerSelection = true
                    // Optionally call any additional ghostRunnerAction behavior.
                    ghostRunnerAction()
                },
                hasActiveGhostRunners: .constant(!ghostRunnerManager.selectedGhostRunners.isEmpty)
            )
            
            // Footwear button only shown if not running and not showing post-run details.
            if !isRunning && !showPostRunDetails {
                FootwearButtonView(selectedFootwear: $selectedFootwear)
            }
        }
        .sheet(isPresented: $showGoalsView) {
            GoalsView()
        }
        // New sheet modifier to present the ghost runner selection view.
        .sheet(isPresented: $showGhostRunnerSelection) {
            GhostRunnerSelectionView(ghostRunnerManager: ghostRunnerManager)
        }
    }
    
    // this helps get the runs for my calendar view
    private func refreshRuns() async {
            do {
                // Replace with your method to fetch runs, similar to your profile view
                let fetchedRuns = try await AuthService.shared.fetchUserRuns()
                // Sort the runs if necessary
                runs = fetchedRuns.sorted { $0.date > $1.date }
            } catch {
                print("DEBUG: Failed to fetch runs: \(error.localizedDescription)")
            }
        }
}



// A simple Goals button styled similarly to your Calendar button.
struct GoalsButtonView: View {
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: "target")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(Color(UIColor.systemBackground))
                .clipShape(Circle())
                .shadow(color: Color.primary.opacity(0.3), radius: 3, x: 0, y: 1)
        }
    }
}

#Preview {
    @State var previewIsRunning = false
    @State var previewShowPostRunDetails = false
    @State var previewFootwear = "Select Footwear"
    @StateObject var ghostRunnerManager = GhostRunnerManager()
    
    return FloatingActionButtonsView(
        isRunning: $previewIsRunning,
        showPostRunDetails: $previewShowPostRunDetails,
        selectedFootwear: $previewFootwear,
        ghostRunnerManager: ghostRunnerManager,
        calendarAction: {
            print("Calendar tapped!")
        },
        goalsAction: {
            print("Goals tapped!")
        },
        ghostRunnerAction: {
            print("Ghost Runner tapped!")
        }
    )
}



