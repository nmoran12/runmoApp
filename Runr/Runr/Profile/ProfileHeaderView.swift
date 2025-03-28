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
    
    var onTapProfileImage: (() -> Void)? = nil
    
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
    
    // New helper that creates a conversation document ID using user IDs.
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
                            .foregroundColor(.gray)
                    }
                    VStack {
                        Text(formatTime(totalTime ?? 0))
                            .font(.system(size: 14, weight: .semibold))
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    VStack {
                        Text("\(averagePace ?? 0, specifier: "%.1f") min/km")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Avg Pace")
                            .font(.caption)
                            .foregroundColor(.gray)
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
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            // Divider to visually separate sections
            Divider()
                .padding(.vertical, 4)
            
            // Follower / Following / Runs counters re-organized into vertical stacks for better clarity
            HStack(spacing: 16) {
                VStack {
                    Text("\(followerCount)")
                        .font(.headline)
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                VStack {
                    Text("\(followingCount)")
                        .font(.headline)
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                VStack {
                    Text("\(runCount)")
                        .font(.headline)
                    Text("Runs")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 8)
            
            // Follow & Message buttons with refined styling
            HStack {
                Button {
                    Task {
                        do {
                            if isFollowing {
                                try await AuthService.shared.unfollowUser(userId: user.id)
                                isFollowing = false
                            } else {
                                try await AuthService.shared.followUser(userId: user.id)
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
                        .background(isFollowing ? Color.gray : Color.blue)
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
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
            }
            .frame(height: 44)
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
                let runs = try await AuthService.shared.fetchUserRuns()
                runCount = runs.count
                let followingStatus = try await AuthService.shared.isCurrentUserFollowingUser(user.id)
                isFollowing = followingStatus
            } catch {
                print("Error fetching run count: \(error.localizedDescription)")
            }
        }
        .navigationDestination(isPresented: .constant(showChat)) {
            ChatView(conversationId: generatedConversationId, userId: user.id)
        }
    }
}

#Preview {
    ProfileHeaderView(
        user: User(
            id: "123",
            username: "Spiderman",
            email: "spiderman@avengers.com",
            realName: "Peter Parker"
        ),
        totalDistance: 100.0,
        totalTime: 3600.0,
        averagePace: 6.0,
        isFirst: true
    )
    .environmentObject(AuthService.shared)
}


