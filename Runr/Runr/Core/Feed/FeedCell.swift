//
//  FeedCell.swift
//  Runr
//
//  Created by Noah Moran on 6/1/2025.
//

import SwiftUI
import MapKit
import UIKit
import FirebaseFirestore


struct FeedCell: View {
    
    @State private var showComments = false //This sets show comment to false by default so it starts off not showing
    @State private var isLiked = false
    @State private var likeCount: Int
    
    var post: Post
    
    init(post: Post) {
        self.post = post
        self._likeCount = State(initialValue: post.likes) // Set initial like count
    }
    
    
    // Function for being able to share posts
    func sharePost() {
        // Ensure runData exists before using it
        guard let runData = post.runData else {
            print("Error: No run data available for this post")
            return
        }

        let postText = "\(post.user.username)'s run – \(runData.distance) km"
        let image = generateSnapshot() // Converts the post into an image

        let activityViewController = UIActivityViewController(
            activityItems: [postText, image], // Ensure we share both text & image
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }

    
    func generateSnapshot() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let size = CGSize(width: 375, height: 500) // Adjust based on your layout
        view?.bounds = CGRect(origin: .zero, size: size)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }

    
    
    func timeAgoSinceDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // Function for liking posts
    func toggleLike() {
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1

        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(post.id)

        postRef.updateData(["likes": likeCount]) { error in
            if let error = error {
                print("Error updating likes: \(error.localizedDescription)")
            } else {
                print("Likes updated successfully in Firestore")
                
                // Fetch updated like count from Firestore to ensure consistency
                postRef.getDocument { document, error in
                    if let document = document, document.exists {
                        if let updatedLikes = document.data()?["likes"] as? Int {
                            DispatchQueue.main.async {
                                self.likeCount = updatedLikes
                            }
                        }
                    } else {
                        print("Error fetching updated likes: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }

    
    var body: some View {
        VStack(alignment: .leading) {
            // MARK: - Post Header (Profile Image & Username)
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                VStack(alignment: .leading) {
                    Text(post.user.username)
                        .font(.system(size: 16, weight: .bold))
                    
                    Text(timeAgoSinceDate(post.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "ellipsis") // Options menu
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)

            // MARK: - Running Data (Now Above the Map)
            if let runData = post.runData {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(post.user.username)'s run - \(String(format: "%.2f km", runData.distance))")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.bottom, 4)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Distance")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(String(format: "%.2f km", runData.distance / 1000))")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time")
                                .font(.caption)
                                .foregroundColor(.gray)
                            let timeMinutes = Int(runData.elapsedTime) / 60
                            let timeSeconds = Int(runData.elapsedTime) % 60
                            Text("\(String(format: "%d min %02d sec", timeMinutes, timeSeconds))")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pace")
                                .font(.caption)
                                .foregroundColor(.gray)
                            let paceInSecondsPerKm = runData.elapsedTime / (runData.distance / 1000)
                            let paceMinutes = Int(paceInSecondsPerKm) / 60
                            let paceSeconds = Int(paceInSecondsPerKm) % 60
                            Text("\(String(format: "%d:%02d / km", paceMinutes, paceSeconds))")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }

            // MARK: - Route Map (Acts as "Post Image")
            if let runData = post.runData, !runData.routeCoordinates.isEmpty {
                RouteMapView(routeCoordinates: runData.routeCoordinates)
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 6)
            }

            // MARK: - Action Buttons (Like, Comment, Share)
            HStack {
                Button(action: {
                    toggleLike()
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .black)
                        .font(.system(size: 22))
                }

                Text("\(likeCount)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                
                // This is the button for comment section and to show the comment section
                Button(action: {
                    showComments.toggle()
                }) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 22))
                }

                .sheet(isPresented: $showComments) {
                    CommentsView(post: post)
                }
                
                // Share post button
                Button(action: {
                    sharePost()
                }) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 22))
                }


                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)

            Divider()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    FeedCell(post: Post.MOCK_POSTS[0])
}
