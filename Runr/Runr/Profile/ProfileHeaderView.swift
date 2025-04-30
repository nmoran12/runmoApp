//
//  ProfileHeaderView.swift
//  InstagramTutorial
//
//  Created by Noah Moran on 3/1/2025.
//

import SwiftUI
import Kingfisher
import FirebaseFirestore
import FirebaseAuth

struct ProfileHeaderView: View {
    @EnvironmentObject var authService: AuthService
    @State private var runCount: Int = 0
    @State private var followerCount: Int = 0
    @State private var followerListener: ListenerRegistration? = nil
    @State private var showChat = false
    @State private var generatedConversationId = ""
    @State private var isFollowing = false
    @State private var followingCount: Int = 0

    let user: User
    let totalDistance: Double?
    let totalTime: Double?
    let averagePace: Double?
    var isFirst: Bool
    let runs: [RunData]
    
    var onTapProfileImage: (() -> Void)? = nil

    // Computed property to check if this is the current user
    var isCurrentUser: Bool {
        return Auth.auth().currentUser?.uid == user.id
    }
    
    // Helper to format time nicely
    func formatTime(_ totalTime: Double) -> String {
        let totalSeconds = Int(totalTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
    
    // Helper that creates a conversation document ID using user IDs.
    func makeConversationDocIdUsingIDs(userId1: String, userId2: String) -> String {
        let sortedIDs = [userId1, userId2].sorted()
        return sortedIDs.joined(separator: "_") + "_chat"
    }

    // Updated startConversation() that uses user IDs.
    private func startConversation() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let otherUserId = user.id
        
        let conversationDocId = makeConversationDocIdUsingIDs(userId1: currentUserId, userId2: otherUserId)
        let db = Firestore.firestore()
        let conversationRef = db.collection("conversations").document(conversationDocId)
        
        conversationRef.getDocument { snapshot, error in
            if let error = error {
                print("DEBUG: Error checking conversation doc: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                DispatchQueue.main.async {
                    generatedConversationId = conversationDocId
                    showChat = true
                }
            } else {
                let conversationData: [String: Any] = [
                    "id": conversationDocId,
                    "users": [currentUserId, otherUserId]
                ]
                conversationRef.setData(conversationData) { error in
                    if let error = error {
                        print("DEBUG: Failed to create conversation: \(error.localizedDescription)")
                    } else {
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut) {
                                generatedConversationId = conversationRef.documentID
                                showChat = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Listen for changes in the user's follower/following data
    private func listenForUserUpdates() {
        let userRef = Firestore.firestore().collection("users").document(user.id)
        followerListener = userRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("DEBUG: Error listening for user updates: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot, snapshot.exists, let data = snapshot.data() {
                if let count = data["followerCount"] as? Int {
                    DispatchQueue.main.async {
                        self.followerCount = count
                    }
                }
                if let followingArray = data["following"] as? [String] {
                    DispatchQueue.main.async {
                        self.followingCount = followingArray.count
                    }
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Profile Header Content
            HStack(alignment: .center) {
                CrownedProfileImage(profileImageUrl: user.profileImageUrl, size: 80, isFirst: isFirst)
                    .frame(width: 80, height: 80)
                    .onTapGesture {
                        onTapProfileImage?()
                    }
                
                Spacer()
                
                // Running stats
                HStack(alignment: .top, spacing: 24) {
                    VStack {
                        Text("\((totalDistance ?? 0), specifier: "%.2f") km")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Distance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack {
                        Text(formatTime(totalTime ?? 0))
                            .font(.system(size: 14, weight: .semibold))
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack {
                        Text("\(averagePace ?? 0, specifier: "%.1f") min/km")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Avg Pace")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 8)
            
            // Username and Bio with extra spacing
            Text(user.username ?? "Unknown User")
                .font(.title2)
                .fontWeight(.semibold)
            Text(user.bio ?? "No bio available")
                .font(.footnote)
                .foregroundColor(.secondary)
                //.padding(.bottom, 2)
            
            // Compute tags from runs and display them
            // Compute dynamic tags using TagsManager
            let dynamicTags = TagsManager.computeTags(from: runs)
            let tagsToDisplay = (user.tags?.isEmpty == false ? user.tags! : dynamicTags)
            if !tagsToDisplay.isEmpty {
                TagsView(tags: tagsToDisplay)
                    .padding(.horizontal, 0)
                    .padding(.bottom, 20)
            }


            
            // Divider to visually separate sections
            Divider()
                //.padding(.vertical, 4)
            
            // Follower / Following / Runs counters
            HStack(spacing: 0) {
                statBlock(count: followerCount, label: "Followers")
                
                Divider()
                    .frame(height: 36)
                
                statBlock(count: followingCount, label: "Following")
                
                Divider()
                    .frame(height: 36)
                
                statBlock(count: runCount, label: "Runs")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground).opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Button Section
            if isCurrentUser {
                NavigationLink(destination: ProfileStatsView(user: user)) {
                    Text("View Stats")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .frame(height: 44)
            } else {
                HStack {
                    Button {
                        Task {
                            do {
                                if isFollowing {
                                    try await authService.unfollowUser(userId: user.id)
                                    isFollowing = false
                                } else {
                                    try await authService.followUser(userId: user.id)
                                    isFollowing = true
                                }
                            } catch {
                                print("DEBUG: Error toggling follow: \(error.localizedDescription)")
                            }
                        }
                    } label: {
                        Text(isFollowing ? "Unfollow" : "Follow")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isFollowing ? Color.secondary : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        startConversation()
                    } label: {
                        Text("Message")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                }
                .frame(height: 44)
            }
        }
        .padding(.horizontal)
        .onAppear {
            listenForUserUpdates()
        }
        .onDisappear {
            followerListener?.remove()
        }
        .task {
            do {
                // pick the right fetch call
                let userRuns: [RunData]
                if isCurrentUser {
                    userRuns = try await authService.fetchUserRuns()
                } else {
                    userRuns = try await authService.fetchUserRuns(for: user.id)
                }

                // update your runCount
                runCount = userRuns.count

                // keep your follow-state logic
                let followingStatus = try await authService.isCurrentUserFollowingUser(user.id)
                isFollowing = followingStatus

                // recompute any tags based on that exact run list
                let dynamicTags = TagsManager.computeTags(from: userRuns)
                try await TagsManager.updateUserTags(dynamicTags)
            } catch {
                print("DEBUG: Failed to load runs or tags: \(error.localizedDescription)")
            }
        }

        .navigationDestination(isPresented: .constant(showChat)) {
            ChatView(conversationId: generatedConversationId, userId: user.id)
        }
    }
}

private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary)
                .shadow(color: Color.primary.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

private func statBlock(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

#Preview {
    // Create some sample RunData
    let sampleRuns: [RunData] = [
        RunData(date: Date(), distance: 5000, elapsedTime: 800, routeCoordinates: []),
        RunData(date: Date(), distance: 10000, elapsedTime: 2300, routeCoordinates: []),
        RunData(date: Date(), distance: 42000, elapsedTime: 12000, routeCoordinates: [])
    ]
    
    return ProfileHeaderView(
        user: User(
            id: "123",
            username: "Spiderman",
            email: "spiderman@avengers.com",
            realName: "Peter Parker"
            // Make sure to include any additional required fields for User.
        ),
        totalDistance: 100.0,
        totalTime: 3600.0,
        averagePace: 6.0,
        isFirst: true,
        runs: sampleRuns
    )
    .environmentObject(AuthService.shared)
}

