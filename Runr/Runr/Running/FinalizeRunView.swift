//
//  FinalizeRunView.swift
//  Runr
//
//  Created by Noah Moran on 27/3/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// A custom notification name used to tell the TabView to switch back to Feed
extension Notification.Name {
    static let didUploadRun = Notification.Name("didUploadRun")
}

struct FinalizeRunView: View {
    @ObservedObject var runTracker: RunTracker
    @EnvironmentObject var viewModel: NewRunningProgramViewModel
    @Binding var selectedFootwear: String
    @Binding var userPostedDistance: Double
    @Binding var nextRankDistance: Double?
    @Binding var distanceToNextRank: Double
    @Binding var userRank: Int?
    @Binding var showPostRunDetails: Bool

    @State private var runTitle: String = "Afternoon Run"
    @State private var activityDescription: String = ""
    @State private var privateNotes: String = ""
    @State private var activityType: String = "Run"
    @State private var activityFeel: String = ""
    @State private var newGear: String = ""
    @State private var selectedVisibility: String = "Followers"
    @State private var hiddenDetails: String = ""
    @State private var isMuted: Bool = false

    @State private var showSaveAlert: Bool = false
    @State private var alertMessage: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Activity Title", text: $runTitle)
                        .font(.headline)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)

                    TextField("How'd it go? Share more about your activity...", text: $activityDescription, axis: .vertical)
                        .frame(minHeight: 80)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)

                    HStack {
                        Text("Type of run:")
                            .font(.subheadline)
                        Spacer()
                        Picker("Type of run", selection: $activityType) {
                            Text("Run").tag("Run")
                            Text("Workout").tag("Workout")
                            Text("Race").tag("Race")
                        }
                        .pickerStyle(.menu)
                    }

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

                    TextField("Jot down private notes here. Only you can see these.", text: $privateNotes, axis: .vertical)
                        .padding()
                        .frame(minHeight: 80)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)

                    HStack {
                        Text("Add new gear!")
                        Spacer()
                        TextField("E.g. new shoes", text: $newGear)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Visibility")
                            .font(.subheadline)
                        Picker("Who can view", selection: $selectedVisibility) {
                            Text("Followers").tag("Followers")
                            Text("Only Me").tag("Only Me")
                            Text("Everyone").tag("Everyone")
                        }
                        .pickerStyle(.menu)
                        HStack {
                            Text("Hidden Details")
                            Spacer()
                            TextField("Choose hidden details...", text: $hiddenDetails)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        }
                    }

                    Toggle(isOn: $isMuted) {
                        Text("Mute Activity")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .orange))

                    Text("Don’t publish to feeds. This activity will still be visible on your profile.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(spacing: 12) {
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

                        Button {
                            Task { await saveActivity() }
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
                    // tell TabView to switch back to feed
                    NotificationCenter.default.post(name: .didUploadRun, object: nil)
                    // then dismiss this view
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Resume") { dismiss() }
                }
            }
        }
    }

    private func discardActivity() {
        runTracker.stopRun()
        runTracker.distanceTraveled = 0
        runTracker.elapsedTime = 0
        runTracker.isRunning = false
        runTracker.paceString = "0:00"
        userPostedDistance = 0
        nextRankDistance = nil
        distanceToNextRank = 0
        userRank = nil
        showPostRunDetails = false
    }

    private func saveActivity() async {
        guard let userId = AuthService.shared.userSession?.uid else { return }
        let oldRank = await fetchUserRank(userId: userId)
        await runTracker.uploadRunData(withCaption: activityDescription, footwear: selectedFootwear)
        await viewModel.loadActiveUserProgram(for: AuthService.shared.currentUser?.username ?? "")
        await viewModel.checkMostRecentRunCompletion()
        let newRank = await fetchUserRank(userId: userId)
        if let old = oldRank, let new = newRank, old > new {
            alertMessage = "Run posted! You gained \(old-new) position\(old-new>1 ? "s":"") on the leaderboard."
        } else {
            alertMessage = "Run posted successfully!"
        }
        showSaveAlert = true
    }

    private func fetchUserRank(userId: String) async -> Int? {
        let snapshot = try? await Firestore.firestore()
            .collection("users").order(by: "totalDistance", descending: true)
            .getDocuments()
        guard let docs = snapshot?.documents,
              let idx = docs.firstIndex(where: { $0.documentID == userId }) else {
            return nil
        }
        return idx + 1
    }
}

#Preview {
    FinalizeRunView(
        runTracker: RunTracker(),
        selectedFootwear: .constant("Shoes"),
        userPostedDistance: .constant(0),
        nextRankDistance: .constant(nil),
        distanceToNextRank: .constant(0),
        userRank: .constant(nil),
        showPostRunDetails: .constant(false)
    )
}
