//
//  FeedCell.swift
//  Runr
//
//  Created by Noah Moran on 6/1/2025.
//

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
    
    @State private var showComments = false // Default to not showing comments
    @State private var isLiked = false
    @State private var likeCount: Int
    @State private var showDetailView = false
    
    var post: Post
    
    init(post: Post) {
        self.post = post
        self._likeCount = State(initialValue: post.likes) // Initialize like count
    }
    
    // Function for sharing posts
    func sharePost() {
        guard let runData = post.runData else {
            print("Error: No run data available for this post")
            return
        }
        
        let postText = "\(post.user.username)'s run – \(runData.distance) km"
        let image = generateSnapshot()
        
        let activityViewController = UIActivityViewController(
            activityItems: [postText, image],
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
    
    func timeAgoSinceDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: RunDetailView(post: post)) {
                VStack(alignment: .leading) {
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
                        
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    
                    if let runData = post.runData {
                        VStack(alignment: .leading, spacing: 4) {
                            if !post.caption.isEmpty {
                                Text(post.caption)
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(.bottom, 4)
                            }

                            
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
                    
                    if let runData = post.runData, !runData.routeCoordinates.isEmpty {
                        RouteMapView(routeCoordinates: runData.routeCoordinates)
                            .frame(height: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.top, 6)
                    }
                }
            }
            // For caption on the post on feed


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
                
                Button(action: {
                    showComments.toggle()
                }) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 22))
                }
                .sheet(isPresented: $showComments) {
                    CommentsView(post: post)
                }
                
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
