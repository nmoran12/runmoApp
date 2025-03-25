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
    
    // Helper to format time nicely
    func formatTime(_ totalTime: Double) -> String {
        let totalSeconds = Int(totalTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d hrs %d mins", hours, minutes)
        } else {
            return String(format: "%d mins %d secs", minutes, seconds)
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
        let otherUserId = user.id  // The recipient's user ID
        
        // Create a stable conversation ID using user IDs.
        let conversationDocId = makeConversationDocIdUsingIDs(userId1: currentUserId, userId2: otherUserId)
        let db = Firestore.firestore()
        let conversationRef = db.collection("conversations").document(conversationDocId)
        
        // Check if a conversation already exists.
        conversationRef.getDocument { snapshot, error in
            if let error = error {
                print("DEBUG: Error checking conversation doc: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                print("DEBUG: Conversation already exists with ID: \(conversationDocId)")
                DispatchQueue.main.async {
                    generatedConversationId = conversationDocId
                    showChat = true  // Trigger navigation.
                }
            } else {
                // Create a new conversation document.
                let conversationData: [String: Any] = [
                    "id": conversationDocId,
                    "users": [currentUserId, otherUserId]
                ]
                conversationRef.setData(conversationData) { error in
                    if let error = error {
                        print("DEBUG: Failed to create conversation: \(error.localizedDescription)")
                    } else {
                        print("DEBUG: Created NEW conversation with ID: \(conversationDocId)")
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut) {
                                self.generatedConversationId = conversationRef.documentID
                                self.showChat = true
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
                    
                    // If you store followerCount as an integer
                    if let count = data["followerCount"] as? Int {
                        DispatchQueue.main.async {
                            self.followerCount = count
                        }
                    }
                    
                    // If you store a 'following' array on the user doc
                    if let followingArray = data["following"] as? [String] {
                        DispatchQueue.main.async {
                            self.followingCount = followingArray.count
                        }
                    }
                    
                    // Alternatively, if you store followingCount as an integer:
                    // if let followingNum = data["followingCount"] as? Int {
                    //     DispatchQueue.main.async {
                    //         self.followingCount = followingNum
                    //     }
                    // }
                }
            }
        }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Profile Header Content
            HStack(alignment: .center) {
                // Profile image and crown
                ZStack {
                    Circle()
                        .stroke(isFirst ? Color.yellow : Color.clear, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    if let imageUrl = user.profileImageUrl,
                       let url = URL(string: imageUrl) {
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                    }
                    
                    if isFirst {
                        Image(systemName: "crown.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.yellow)
                            .offset(y: -50)
                    }
                }
                
                Spacer()
                
                // Running stats
                HStack(spacing: 20) {
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
            
            // Username, Bio, etc.
            Text(user.username ?? "Unknown User")
                .font(.title2)
                .fontWeight(.semibold)
            Text(user.bio ?? "No bio available")
                .font(.footnote)
                .foregroundColor(.gray)
            
            HStack(spacing: 8){
                
                Text("Followers: ")
                    .fontWeight(.semibold)
                
                Text("\(followerCount)")
                    .font(.footnote)
                
                Text("Following: ")
                    .fontWeight(.semibold)
                
                Text("\(followingCount)")
                    .font(.footnote)
                
                Text("Runs: ")
                    .fontWeight(.semibold)
                
                Text("\(runCount)")
                    .font(.footnote)
            }
            
            // Follow & Message buttons
            HStack {
                Button {
                    Task {
                        do {
                            if isFollowing {
                            // Already following -> Unfollow
                            try await AuthService.shared.unfollowUser(userId: user.id)
                            isFollowing = false
                        } else {
                            // Not following -> Follow
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
                        .padding(.vertical, 8)
                        .background(isFollowing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Button {
                    print("DEBUG: About to start conversation")
                    print("DEBUG: currentUserId = \(Auth.auth().currentUser?.uid ?? "nil")")
                    print("DEBUG: user.id = \(user.id)")
                    startConversation()
                } label: {
                    Text("Message")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(4)
                }
            }
            .frame(height: 36)
        }
        .padding(.horizontal)
        .onAppear {
                    // Start listening for follower count updates when the view appears.
                    listenForUserUpdates()
                }
                .onDisappear {
                    // Remove the listener to prevent memory leaks.
                    followerListener?.remove()
                }
        .task {
            do {
                let runs = try await AuthService.shared.fetchUserRuns()
                runCount = runs.count
                
                // Check if current user is following this user
                let followingStatus = try await AuthService.shared.isCurrentUserFollowingUser(user.id)
                isFollowing = followingStatus
            } catch {
                print("Error fetching run count: \(error.localizedDescription)")
            }
        }
        .navigationDestination(isPresented: $showChat) {
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

