//
//  RunningView.swift
//  Runr
//
//  Created by Noah Moran on 24/3/2025.
//

import SwiftUI
import FirebaseFirestore

struct RunningView: View {
    @StateObject var runTracker = RunTracker()
    @State private var isPressed = false
    @State private var showPostRunDetails = false // Instead of navigation link
    @State private var selectedFootwear: String = "Select Footwear"
    @Environment(\.presentationMode) var presentationMode
    @StateObject var ghostRunnerManager = GhostRunnerManager() // Shared manager
    
    @State private var caption: String = ""
    @State private var showPostAlert: Bool = false
    @State private var postAlertMessage: String = ""
    @State private var userRank: Int? = nil
    @State private var userPostedDistance: Double = 0.0   // The distance from Firestore
    @State private var nextRankDistance: Double? = nil    // The next user's total distance
    @State private var distanceToNextRank: Double = 0.0   // Computed difference
    @State private var showFinalizeScreen = false



    // For controlling navigation to LeaderboardView
    @State private var showLeaderboard: Bool = false
    
    // Add this to track if we're showing loading state
    @State private var isLoadingRank: Bool = true
    
    // State to control showing the CalendarView.
    @State private var showCalendarView: Bool = false
    @State private var runs: [RunData] = []
    
    @State private var showGoalsSettingView: Bool = false

    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map Layer
                AreaMap(region: $runTracker.region)
                    .edgesIgnoringSafeArea(.all)
                
                // UI Overlays
                VStack(alignment: .trailing, spacing: 0) {
                        
                    VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    FloatingActionButtonsView(
                                        isRunning: $runTracker.isRunning,
                                        showPostRunDetails: $showPostRunDetails,
                                        selectedFootwear: $selectedFootwear,
                                        ghostRunnerManager: ghostRunnerManager, // or your existing manager
                                        calendarAction: {
                                            showCalendarView = true
                                        },
                                        goalsAction: {
                                            showGoalsSettingView = true
                                        },
                                        ghostRunnerAction: {
                                            // Do something when Ghost Runner is tapped, or leave empty
                                            print("Ghost Runner tapped")
                                        }
                                    )

                                    .padding(16) // Adjust for positioning
                                }
                            }
                    .onAppear {
                        Task {
                            // Fetch runs from your backend and assign to the runs state variable.
                            self.runs = try await AuthService.shared.fetchUserRuns()
                        }
                    }
                    .sheet(isPresented: $showGoalsSettingView) {
                        GoalsSettingView()
                    }

                    .sheet(isPresented: $showCalendarView) {
                        CalendarView(runs: runs)
                    }
                    
                    Spacer()
                    
                    // Main stats display and controls
                    VStack(spacing: 0) {
                        // Instead of always showing the leaderboard bar,
                        // conditionally display GhostRunnerStatusView when ghost runners are selected.
                        if !ghostRunnerManager.selectedGhostRunners.isEmpty {
                            GhostRunnerStatusView(
                                ghostRunners: ghostRunnerManager.selectedGhostRunners,
                                userDistance: runTracker.distanceTraveled
                            )
                        } else {
                            leaderboardBar
                        }
                        
                        // Main stats row
                        statsRow
                        
                        if !showPostRunDetails {
                            // Running controls
                            runningControls
                        } else {
                            // Post-run expanded details (growing from bottom)
                            postRunExpandedView
                        }
                    }
                    .background(Color(.systemBackground))
                }
            }
            // Update navigation bar items to include a calendar button on the leading side.
            .navigationBarItems(
                leading: HStack {
                    Button(action: {
                        // Existing back action:
                        runTracker.stopRun()
                        runTracker.distanceTraveled = 0
                        runTracker.elapsedTime = 0
                        runTracker.isRunning = false
                        
                        // Reset ephemeral leaderboard info
                        userPostedDistance = 0
                        nextRankDistance = nil
                        distanceToNextRank = 0
                        userRank = nil
                        
                        // Hide the post-run UI if showing
                        showPostRunDetails = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                            .padding(8)
                    }
                },
                trailing: Button(action: {
                    // More options
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                        .padding(8)
                }
            )
        }
        .onAppear {
            // Start a timer to update ghost runner positions every second.
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                // If the run is no longer active, stop the timer.
                if !runTracker.isRunning {
                    timer.invalidate()
                } else {
                    ghostRunnerManager.updateSelectedGhostRunnerPositions(elapsedTime: runTracker.elapsedTime)
                }
            }
            
            // Your existing onAppear code for fetching leaderboard info etc.
            Task {
                guard let userId = AuthService.shared.userSession?.uid else { return }
                let (rank, postedDist, nextDist) = await fetchLeaderboardInfo(for: userId)
                self.userRank = rank
                self.userPostedDistance = postedDist ?? 0
                self.nextRankDistance = nextDist
                computeDistanceToNextRank()
            }
        }

        .onReceive(runTracker.$distanceTraveled) { _ in
            // This fires every time distanceTraveled changes
            computeDistanceToNextRank()
        }
        // -- Alert for Post Success --
        .alert("Post Run", isPresented: $showPostAlert) {
            Button("OK") {
                // Hide the post-run details
                showPostRunDetails = false
                
                // Reset the caption field
                caption = ""
                
                // Stop the run and reset the runTracker properties
                runTracker.stopRun()
                runTracker.distanceTraveled = 0
                runTracker.elapsedTime = 0
                runTracker.isRunning = false
                runTracker.paceString = "0:00"
                
                // Reset ephemeral leaderboard info
                userPostedDistance = 0
                nextRankDistance = nil
                distanceToNextRank = 0
                userRank = nil
            }
        } message: {
            Text(postAlertMessage)
        }
    }
    
    // MARK: - UI Components
    
    private var footwearButton: some View {
            FootwearButtonView(selectedFootwear: $selectedFootwear)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .transition(.opacity)
        }
    
    private var leaderboardBar: some View {
        Button {
            // On tap, navigate to LeaderboardView
            showLeaderboard = true
        } label: {
            HStack {
                // Trophy icon in circle
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                    )
                    .padding(.leading, 5)
                
                // Leaderboard text
                VStack(alignment: .leading, spacing: 1) {
                    if let rank = userRank {
                        Text("You are #\(rank) on the leaderboard")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        if rank > 1 {
                            // Show how far to next rank
                            Text(
                                distanceToNextRank > 0
                                ? String(format: "You are %.2f km away from the next rank", distanceToNextRank)
                                : "You’ve surpassed the next rank if you post now!"
                            )
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
                
                // ">" icon
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
        .buttonStyle(PlainButtonStyle()) // So it doesn't look like a default SwiftUI button
        .background(
            // Invisible NavigationLink that triggers on showLeaderboard = true
            NavigationLink(destination: LeaderboardsView(), isActive: $showLeaderboard) {
                EmptyView()
            }
            .hidden()
        )
    }

    
    private var statsRow: some View {
        HStack(spacing: 0) {
            // AVG Pace Column
            VStack(alignment: .center, spacing: 2) {
                Text("AVG Pace")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 1) {
                    Text(runTracker.paceString.replacingOccurrences(of: " / km", with: ""))
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("/km")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            
            Divider()
                .frame(width: 1, height: 70)
                .background(Color.secondary.opacity(0.3))
            
            // Distance Column
            VStack(alignment: .center, spacing: 2) {
                Text("Distance")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 1) {
                    Text(String(format: "%.2f", runTracker.distanceTraveled / 1000))
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("km")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            
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
    
    private var runningControls: some View {
        Group {
            if !runTracker.isRunning {
                // Start Run controls
                HStack(spacing: 40) {
                    
                    Button {
                        runTracker.startRun()
                    } label: {
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
                    
                }
                .padding(.vertical, 30)
                .background(Color(.systemBackground))
            } else {
                // Stop Run button
                Button {
                    runTracker.pauseRun()
                    // Instead of setting showRunInfo to trigger navigation,
                    // set showPostRunDetails to transition to expanded view
                    withAnimation {
                        showPostRunDetails = true
                    }
                } label: {
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
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private var postRunExpandedView: some View {
        VStack(spacing: 16) {
            // Additional stats that appear when run is completed
            HStack(spacing: 0) {
                // Calories
                VStack(alignment: .center, spacing: 2) {
                    Text("Calories")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 1) {
                        // Calculated calories based on distance/time
                        let calories = Int(runTracker.distanceTraveled * 0.06)
                        Text("\(calories)")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("kcal")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                
                Divider()
                    .frame(width: 1, height: 70)
                    .background(Color.secondary.opacity(0.3))
                
                // Elevation
                VStack(alignment: .center, spacing: 2) {
                    Text("Elevation")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 1) {
                        Text("12")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("m")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                
                Divider()
                    .frame(width: 1, height: 70)
                    .background(Color.secondary.opacity(0.3))
                
                // Heart Rate
                VStack(alignment: .center, spacing: 2) {
                    Text("BPM")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 1) {
                        Text("120")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("bpm")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            
            // Caption input
            TextField("Write a caption...", text: $caption)
                .padding()
                .background(Color(UIColor.systemGray6).opacity(0.6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Post Run Actions
            // This button resumes the run so you can pick up from where you paused it.
            HStack(spacing: 40) {
                Button {
                    // Resume action: simply hide the post-run details and resume the same run.
                    withAnimation {
                        runTracker.resumeRun()
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
                
                
                // "Post" button that takes you to the final posting screen
                Button {
                    // Just show the new finalize screen
                    showFinalizeScreen = true
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
                
                // 3) **Delete** button
                Button {
                    // "Delete" or "discard" the run
                    runTracker.stopRun()
                    runTracker.distanceTraveled = 0
                    runTracker.elapsedTime = 0
                    runTracker.isRunning = false
                    runTracker.paceString = "0:00"
                    
                    // Reset ephemeral leaderboard info
                    userPostedDistance = 0
                    nextRankDistance = nil
                    distanceToNextRank = 0
                    userRank = nil
                    
                    // Hide the post-run UI
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
        .background(Color(.systemBackground))
        .transition(.move(edge: .bottom))
        // Attach a .navigationDestination that listens to showFinalizeScreen
        .navigationDestination(isPresented: $showFinalizeScreen) {
            // Present the new view
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
    
    
    
    // SOME LOGIC FUNCTIONS TO DO WITH THE RUNNING VIEW
    // Returns (userRank, userDistance, nextRankDistance)
    func fetchLeaderboardInfo(for userId: String) async -> (Int?, Double?, Double?) {
        let db = Firestore.firestore()
        
        do {
            // Fetch all users sorted by totalDistance descending
            let snapshot = try await db.collection("users")
                .order(by: "totalDistance", descending: true)
                .getDocuments()
            
            let docs = snapshot.documents
            
            // Find the current user
            guard let userIndex = docs.firstIndex(where: { $0.documentID == userId }) else {
                return (nil, nil, nil)
            }
            
            let userDoc = docs[userIndex]
            let userDistance = userDoc.data()["totalDistance"] as? Double ?? 0
            
            // user rank is 1-indexed
            let userRank = userIndex + 1
            
            // If user is not #1, find the distance of the next user up
            if userIndex > 0 {
                let nextUserDoc = docs[userIndex - 1] // user above in the sorted array
                let nextUserDistance = nextUserDoc.data()["totalDistance"] as? Double ?? 0
                return (userRank, userDistance, nextUserDistance)
            } else {
                // user is #1, so there's no next user above them
                return (userRank, userDistance, nil)
            }
        } catch {
            print("DEBUG: Error fetching leaderboard info - \(error)")
            return (nil, nil, nil)
        }
    }
    
    // Helper function to format time
    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    // Helper function to compute how many kilometres to go until a user reaches the next
    // rank on a leaderboard
    private func computeDistanceToNextRank() {
        // If there's no next rank, user is #1 or rank is unknown
        guard let nextUserDist = nextRankDistance else {
            distanceToNextRank = 0
            return
        }
        // The user's ephemeral distance is userPostedDistance + whatever they've run this session
        let ephemeralUserDistance = userPostedDistance + runTracker.distanceTraveled
        
        // How far behind next rank are we?
        let diff = nextUserDist - ephemeralUserDistance
        // If user is already beyond that distance, set 0 or negative
        distanceToNextRank = diff > 0 ? diff : 0
    }

}

#Preview {
    RunningView()
        .preferredColorScheme(.dark)
}

