//
//  FinalizeRunView.swift
//  Runr
//
//  Created by Noah Moran on 27/3/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FinalizeRunView: View {
    @ObservedObject var runTracker: RunTracker
    @EnvironmentObject var viewModel: NewRunningProgramViewModel
    @Binding var selectedFootwear: String
    
    // Replace these with whatever data you want from the user:
    @State private var runTitle: String = "Afternoon Run"
    @State private var activityDescription: String = ""
    @State private var privateNotes: String = ""
    @State private var activityType: String = "Run"
    @State private var activityFeel: String = ""
    @State private var newGear: String = ""
    
    @State private var selectedVisibility: String = "Followers"
    @State private var hiddenDetails: String = ""
    @State private var isMuted: Bool = false
    
    // For controlling alerts or sheet dismissal
    @State private var showSaveAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // these variables come from RunningView to make the delete/discard button work
    @Binding var userPostedDistance: Double
    @Binding var nextRankDistance: Double?
    @Binding var distanceToNextRank: Double
    @Binding var userRank: Int?
    @Binding var showPostRunDetails: Bool
    
    // Access SwiftUI’s dismiss environment to pop this view
    @Environment(\.dismiss) private var dismiss
    
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // MARK: - Basic Info
                    TextField("Activity Title", text: $runTitle)
                        .font(.headline)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    
                    TextField("How'd it go? Share more about your activity...", text: $activityDescription, axis: .vertical)
                        .frame(minHeight: 80)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)


                    
                    // MARK: - Activity Type
                    HStack {
                        Text("Type of run:")
                            .font(.subheadline)
                        Spacer()
                        Picker("Type of run", selection: $activityType) {
                            Text("Run").tag("Run")
                            Text("Workout").tag("Workout")
                            Text("Race").tag("Race")
                            // Add more as needed
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // MARK: - How did it feel?
                    HStack {
                        Text("How did that activity feel?")
                            .font(.subheadline)
                        Spacer()
                        Picker("Feel", selection: $activityFeel) {
                            Text("Easy").tag("Easy")
                            Text("Moderate").tag("Moderate")
                            Text("Hard").tag("Hard")
                            Text("Suffering").tag("Suffering")
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // MARK: - Private Notes
                    TextField("Jot down private notes here. Only you can see these.", text: $privateNotes, axis: .vertical)
                        .padding()
                        .frame(minHeight: 80)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    
                    // MARK: - Gear
                    HStack {
                        Text("Add new gear!")
                        Spacer()
                        TextField("E.g. new shoes", text: $newGear)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                    }
                    
                    // MARK: - Visibility
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Visibility")
                            .font(.subheadline)
                        
                        Picker("Who can view", selection: $selectedVisibility) {
                            Text("Followers").tag("Followers")
                            Text("Only Me").tag("Only Me")
                            Text("Everyone").tag("Everyone")
                        }
                        .pickerStyle(.menu)
                        
                        // Hidden details example
                        HStack {
                            Text("Hidden Details")
                            Spacer()
                            TextField("Choose hidden details...", text: $hiddenDetails)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        }
                    }
                    
                    // MARK: - Mute Activity
                    Toggle(isOn: $isMuted) {
                        Text("Mute Activity")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                    
                    Text("Don’t publish to feeds. This activity will still be visible on your profile.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // MARK: - Bottom Buttons
                    VStack(spacing: 12) {
                        // Discard
                        Button(role: .destructive) {
                            discardActivity()
                        } label: {
                            Text("Discard Activity")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                        
                        // Save
                        Button {
                            Task {
                                await saveActivity()
                            }
                        } label: {
                            Text("Save Activity")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Save Activity")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Activity Posted", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) {
                    // Dismiss after success
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // If you want a "Resume" button to just go back
                    Button("Resume") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Discard the run
    private func discardActivity() {
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
    }
    
    // MARK: - Save (Post) the run
    private func saveActivity() async {
        guard let userId = AuthService.shared.userSession?.uid,
                  let username = AuthService.shared.currentUser?.username else {
                print("DEBUG: No user logged in.")
                return
            }
        
        // Optionally fetch old rank if you want to see if user advanced
        let oldRank = await fetchUserRank(userId: userId)
        
        // Actually upload run data to Firestore
        await runTracker.uploadRunData(
            withCaption: activityDescription,
            footwear: selectedFootwear
        )
        
        // Ensure the active user program is loaded.
        await viewModel.loadActiveUserProgram(for: username)
        
        await viewModel.checkMostRecentRunCompletion()
        
        // Optionally fetch new rank and see if user advanced
        let newRank = await fetchUserRank(userId: userId)
        
        if let oldRank = oldRank, let newRank = newRank, oldRank > newRank {
            let positionsGained = oldRank - newRank
            alertMessage = "Run posted! You gained \(positionsGained) position\(positionsGained > 1 ? "s" : "") on the leaderboard."
        } else {
            alertMessage = "Run posted successfully!"
        }
        
        showSaveAlert = true
    }
    
    // MARK: - Example fetchUserRank
    private func fetchUserRank(userId: String) async -> Int? {
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("users")
                .order(by: "totalDistance", descending: true)
                .getDocuments()
            
            let docs = snapshot.documents
            guard let userIndex = docs.firstIndex(where: { $0.documentID == userId }) else {
                return nil
            }
            // 1-based
            return userIndex + 1
        } catch {
            print("DEBUG: Error fetching rank - \(error)")
            return nil
        }
    }
}


#Preview {
    FinalizeRunView(
        runTracker: RunTracker(),                // an @ObservedObject
        selectedFootwear: .constant("Shoes"),    // a @Binding<String>
        userPostedDistance: .constant(0.0),      // a @Binding<Double>
        nextRankDistance: .constant(nil),        // a @Binding<Double?>
        distanceToNextRank: .constant(0.0),      // a @Binding<Double>
        userRank: .constant(nil),                // a @Binding<Int?>
        showPostRunDetails: .constant(false)     // a @Binding<Bool>
    )
}

