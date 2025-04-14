//
//  RunningView.swift
//  Runr
//
//  Created by Noah Moran on 24/3/2025.
//

import SwiftUI
#if os(iOS)
import FirebaseFirestore
#endif

struct RunningView: View {
    // MARK: - State Objects & Environment Variables
    @StateObject var runTracker = RunTracker()
    @StateObject var ghostRunnerManager = GhostRunnerManager() // Shared manager
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: NewRunningProgramViewModel

    // MARK: - State Variables
    @State private var isPressed = false
    @State private var showPostRunDetails = false
    @State private var selectedFootwear: String = "Select Footwear"
    @State private var caption: String = ""
    @State private var showPostAlert: Bool = false
    @State private var postAlertMessage: String = ""
    @State private var userRank: Int? = nil
    @State private var userPostedDistance: Double = 0.0   // The distance from Firestore
    @State private var nextRankDistance: Double? = nil    // The next user's total distance
    @State private var distanceToNextRank: Double = 0.0   // Computed difference
    @State private var showFinalizeScreen = false
    @State private var showLeaderboard: Bool = false
    @State private var isLoadingRank: Bool = true
    @State private var showCalendarView: Bool = false
    @State private var runs: [RunData] = []
    @State private var showGoalsSettingView: Bool = false

    // MARK: - Constant & Optional Variables
    var targetDistance: Double? = nil
    var runningProgramTargetDistance: Double?

    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                AreaMap(region: $runTracker.region)
                    .edgesIgnoringSafeArea(.all)
                
                // Overlay ghost runner path if one is selected
                if let ghostRunner = ghostRunnerManager.selectedGhostRunners.first {
                    GhostRunnerPath(ghostRunner: ghostRunner, region: runTracker.region)
                }
                
                // UI Overlays
                VStack(alignment: .trailing, spacing: 0) {
                    topOverlayViews
                    Spacer()
                    statsAndControlsView
                }
            }
            .navigationBarItems(
                leading: leadingNavigationButton,
                trailing: trailingNavigationButton
            )
        }
        .onAppear(perform: onViewAppear) // Set up necessary states when view appears
        .onReceive(runTracker.$distanceTraveled) { _ in
            computeDistanceToNextRank() // Update distance to the next rank on distance change
        }
        .alert("Post Run", isPresented: $showPostAlert) {
            Button("OK", action: resetPostRun) // Reset after a post alert confirmation
        } message: {
            Text(postAlertMessage)
        }
    }
    
    // MARK: - Top Overlay & Navigation Views
    
    /// Displays the floating action buttons and associated sheets.
    private var topOverlayViews: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButtonsView(
                    isRunning: $runTracker.isRunning,
                    showPostRunDetails: $showPostRunDetails,
                    selectedFootwear: $selectedFootwear,
                    ghostRunnerManager: ghostRunnerManager,
                    calendarAction: { showCalendarView = true },
                    goalsAction: { showGoalsSettingView = true },
                    ghostRunnerAction: {
                        print("Ghost Runner tapped")
                    }
                )
                .padding(16)
            }
        }
        .onAppear {
            Task {
                self.runs = try await AuthService.shared.fetchUserRuns() // Fetch user's runs for calendar
            }
        }
        .sheet(isPresented: $showGoalsSettingView) {
            GoalsSettingView()
        }
        .sheet(isPresented: $showCalendarView) {
            CalendarView(runs: runs)
        }
    }
    
    /// Combines statistics display and running controls in one view.
    private var statsAndControlsView: some View {
        VStack(spacing: 0) {
            if let userProgram = viewModel.currentUserProgram,
               let todayPlan = viewModel.getTodaysDailyPlan(),
               !viewModel.currentDailyRunIsCompleted {
                
                let dailyRunType = todayPlan.dailyRunType ?? "Unknown"
                RunningProgramBarView(
                    targetDistance: viewModel.currentDailyTargetDistance,
                    currentDistance: runTracker.distanceTraveled,
                    dailyRunType: dailyRunType
                )
            } else if !ghostRunnerManager.selectedGhostRunners.isEmpty {
                GhostRunnerStatusView(
                    ghostRunners: ghostRunnerManager.selectedGhostRunners,
                    userDistance: runTracker.distanceTraveled
                )
            } else {
                leaderboardBar
            }
            
            statsRow
            
            if !showPostRunDetails {
                runningControls
            } else {
                postRunExpandedView
            }
        }
        .background(Color(.systemBackground))
    }
    
    // Navigation button to exit the run, resetting the run and leaderboard data.
    private var leadingNavigationButton: some View {
        HStack {
            Button(action: resetRunAndLeaderboardInfo) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
                    .padding(8)
            }
        }
    }
    
    // Navigation button for additional options.
    private var trailingNavigationButton: some View {
        Button(action: {
            // More options
        }) {
            Image(systemName: "ellipsis")
                .foregroundColor(.primary)
                .padding(8)
        }
    }
    
    // MARK: - UI Component Computed Properties
    
    // A button-styled leaderboard display.
    private var leaderboardBar: some View {
        Button {
            showLeaderboard = true
        } label: {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                    )
                    .padding(.leading, 5)
                
                VStack(alignment: .leading, spacing: 1) {
                    if let rank = userRank {
                        Text("You are #\(rank) on the leaderboard")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        if rank > 1 {
                            Text(distanceToNextRank > 0
                                    ? String(format: "You are %.2f km away from the next rank", distanceToNextRank)
                                    : "You’ve surpassed the next rank if you post now!")
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .padding(.leading, 4)
                        } else {
                            Text("You are #1!")
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .padding(.leading, 4)
                        }
                    } else {
                        Text("Leaderboard")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                        Text("Unable to load position")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .padding(.leading, 4)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 10)
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6).opacity(0.6))
            .cornerRadius(8)
            .padding(.horizontal, 10)
            .padding(.top, 15)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            NavigationLink(destination: LeaderboardsView(), isActive: $showLeaderboard) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    // Displays running statistics in a row.
    private var statsRow: some View {
        HStack(spacing: 0) {
            // Average Pace Column
            statColumn(title: "AVG Pace", value: runTracker.paceString.replacingOccurrences(of: " / km", with: ""), unit: "/km", fontSize: 32)
            
            Divider()
                .frame(width: 1, height: 70)
                .background(Color.secondary.opacity(0.3))
            
            // Distance Column
            statColumn(title: "Distance", value: String(format: "%.2f", runTracker.distanceTraveled / 1000), unit: "km", fontSize: 32)
            
            Divider()
                .frame(width: 1, height: 70)
                .background(Color.secondary.opacity(0.3))
            
            // Time Column
            VStack(alignment: .center, spacing: 2) {
                Text("Time")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text(formatTime(seconds: Int(runTracker.elapsedTime)))
                    .font(.system(size: 32, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // Creates a statistic column with a title, value, and unit.
    private func statColumn(title: String, value: String, unit: String, fontSize: CGFloat) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            HStack(alignment: .bottom, spacing: 1) {
                Text(value)
                    .font(.system(size: fontSize, weight: .bold))
                Text(unit)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    // Displays running start/stop control buttons.
    private var runningControls: some View {
        Group {
            if !runTracker.isRunning {
                Button(action: {
                    withAnimation {
                        runTracker.startRun() // Start the run
                    }
                }) {
                    Text("Start")
                        .bold()
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .primary.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .opacity(isPressed ? 0.8 : 1.0)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in withAnimation { isPressed = true } }
                        .onEnded { _ in withAnimation { isPressed = false } }
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color(.systemBackground))
                .animation(.easeInOut(duration: 0.2), value: isPressed)
            } else {
                Button(action: {
                    runTracker.pauseRun() // Pause the run
                    withAnimation {
                        showPostRunDetails = true // Show post-run details
                    }
                }) {
                    Text("STOP")
                        .bold()
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(width: 80, height: 80)
                        .background(Color.red)
                        .clipShape(Circle())
                        .shadow(color: .primary.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .opacity(isPressed ? 0.8 : 1.0)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in withAnimation { isPressed = true } }
                        .onEnded { _ in withAnimation { isPressed = false } }
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color(.systemBackground))
                .animation(.easeInOut(duration: 0.2), value: isPressed)
            }
        }
    }
    
    // Displays the expanded view after a run with additional stats, caption, and action buttons.
    private var postRunExpandedView: some View {
        VStack(spacing: 16) {
            postRunStatsRow
            
            // Caption input field
            TextField("Write a caption...", text: $caption)
                .padding()
                .background(Color(UIColor.systemGray6).opacity(0.6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            postRunActionButtons
        }
        .background(Color(.systemBackground))
        .transition(.move(edge: .bottom))
        .navigationDestination(isPresented: $showFinalizeScreen) {
            FinalizeRunView(
                runTracker: runTracker,
                selectedFootwear: $selectedFootwear,
                userPostedDistance: $userPostedDistance,
                nextRankDistance: $nextRankDistance,
                distanceToNextRank: $distanceToNextRank,
                userRank: $userRank,
                showPostRunDetails: $showPostRunDetails
            )
        }
    }
    
    // Shows additional post-run statistics such as calories, elevation, and BPM.
    private var postRunStatsRow: some View {
        HStack(spacing: 0) {
            // Calories Column
            statColumn(title: "Calories", value: "\(Int(runTracker.distanceTraveled * 0.06))", unit: "kcal", fontSize: 28)
            
            Divider()
                .frame(width: 1, height: 70)
                .background(Color.secondary.opacity(0.3))
            
            // Elevation Column
            statColumn(title: "Elevation", value: "12", unit: "m", fontSize: 28)
            
            Divider()
                .frame(width: 1, height: 70)
                .background(Color.secondary.opacity(0.3))
            
            // Heart Rate Column
            statColumn(title: "BPM", value: "120", unit: "bpm", fontSize: 28)
        }
        .background(Color(.systemBackground))
    }
    
    // Displays action buttons for resuming, posting, or deleting the run.
    private var postRunActionButtons: some View {
        HStack(spacing: 40) {
            // Resume Button
            Button {
                withAnimation {
                    runTracker.resumeRun() // Resume the paused run
                    showPostRunDetails = false
                }
            } label: {
                Text("Resume")
                    .bold()
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Color(.systemGreen))
                    .clipShape(Circle())
                    .shadow(color: .primary.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            
            // Post Button to show final posting screen
            Button {
                showFinalizeScreen = true // Navigate to final posting screen
            } label: {
                Text("Post")
                    .bold()
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(color: .primary.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            
            // Delete Button to discard the run
            Button {
                runTracker.stopRun() // Stop the run
                runTracker.distanceTraveled = 0
                runTracker.elapsedTime = 0
                runTracker.isRunning = false
                runTracker.paceString = "0:00"
                
                userPostedDistance = 0
                nextRankDistance = nil
                distanceToNextRank = 0
                userRank = nil
                showPostRunDetails = false
            } label: {
                Text("Delete")
                    .bold()
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(color: .primary.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.vertical, 20)
    }
    
    
    // MARK: - Lifecycle & Helper Methods
    
    // Called when the view appears. Sets up run tracker, leaderboard info, and ghost runners.
    private func onViewAppear() {
        // Link the runTracker with ghostRunnerManager
        runTracker.setGhostRunnerManager(ghostRunnerManager)
        
        Task {
            guard let userId = AuthService.shared.userSession?.uid else { return }
            let (rank, postedDist, nextDist) = await fetchLeaderboardInfo(for: userId)
            self.userRank = rank
            self.userPostedDistance = postedDist ?? 0
            self.nextRankDistance = nextDist
            computeDistanceToNextRank() // Compute the distance required for next rank
            
            // Fetch runs for the calendar
            self.runs = try await AuthService.shared.fetchUserRuns()
        }
        
        // Load available ghost runners
        Task {
            await ghostRunnerManager.loadAvailableGhostRunners()
        }
    }
    
    // Resets the run and associated leaderboard info.
    private func resetRunAndLeaderboardInfo() {
        runTracker.stopRun()
        runTracker.distanceTraveled = 0
        runTracker.elapsedTime = 0
        runTracker.isRunning = false
        
        userPostedDistance = 0
        nextRankDistance = nil
        distanceToNextRank = 0
        userRank = nil
        
        showPostRunDetails = false
    }
    
    // Resets post-run state after dismissing the post-run alert.
    private func resetPostRun() {
        showPostRunDetails = false
        caption = ""
        runTracker.stopRun()
        runTracker.distanceTraveled = 0
        runTracker.elapsedTime = 0
        runTracker.isRunning = false
        runTracker.paceString = "0:00"
        
        userPostedDistance = 0
        nextRankDistance = nil
        distanceToNextRank = 0
        userRank = nil
    }
    
    
    // MARK: - Helper Functions
    
    // Fetches leaderboard information for a given user ID. Returns (userRank, userDistance, nextUserDistance)
    func fetchLeaderboardInfo(for userId: String) async -> (Int?, Double?, Double?) {
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("users")
                .order(by: "totalDistance", descending: true)
                .getDocuments()
            
            let docs = snapshot.documents
            
            guard let userIndex = docs.firstIndex(where: { $0.documentID == userId }) else {
                return (nil, nil, nil)
            }
            
            let userDoc = docs[userIndex]
            let userDistance = userDoc.data()["totalDistance"] as? Double ?? 0
            let userRank = userIndex + 1
            
            if userIndex > 0 {
                let nextUserDoc = docs[userIndex - 1]
                let nextUserDistance = nextUserDoc.data()["totalDistance"] as? Double ?? 0
                return (userRank, userDistance, nextUserDistance)
            } else {
                return (userRank, userDistance, nil)
            }
        } catch {
            print("DEBUG: Error fetching leaderboard info - \(error)")
            return (nil, nil, nil)
        }
    }
    
    // Formats a time interval in seconds into a minute:second string.
    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    // Computes the distance required to reach the next leaderboard rank.
    private func computeDistanceToNextRank() {
        guard let nextUserDist = nextRankDistance else {
            distanceToNextRank = 0
            return
        }
        let ephemeralUserDistance = userPostedDistance + runTracker.distanceTraveled
        let diff = nextUserDist - ephemeralUserDistance
        distanceToNextRank = diff > 0 ? diff : 0
    }
}

// MARK: - Preview
#Preview {
    RunningView()
        .preferredColorScheme(.dark)
}
