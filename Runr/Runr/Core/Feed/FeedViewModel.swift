//
//  FeedViewModel.swift
//  Runr
//
//  Created by Noah Moran on 14/1/2025.
//

import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI
import CoreLocation
import FirebaseAuth

@MainActor
class FeedViewModel: ObservableObject {
    
    @Published var posts: [Post] = []
    
    func fetchPosts() async {
        print("DEBUG: Fetching posts...")
        
        do {
            let postsSnapshot = try await Firestore.firestore().collection("posts")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            var fetchedPosts: [Post] = []
            
            for postDoc in postsSnapshot.documents {
                let postData = postDoc.data()
                
                guard
                    let postId = postData["id"] as? String,
                    let userId = postData["ownerUid"] as? String,
                    let username = postData["username"] as? String,
                    let runId = postData["runId"] as? String, // Get run reference
                    let likes = postData["likes"] as? Int,
                    let timestamp = (postData["timestamp"] as? Timestamp)?.dateValue()
                else {
                    print("DEBUG: Skipping post due to missing fields -> \(postData)") // Print the post data
                    continue
                }

                
                let userRef = Firestore.firestore().collection("users").document(userId)
                let runRef = userRef.collection("runs").document(runId) // Fetch run data
                
                let runSnapshot = try? await runRef.getDocument()
                guard let runData = runSnapshot?.data(),
                      let distance = runData["distance"] as? Double,
                      let elapsedTime = runData["elapsedTime"] as? Double,
                      let routeCoordinatesArray = runData["routeCoordinates"] as? [[String: Double]]
                else {
                    print("DEBUG: Skipping run due to missing fields")
                    continue
                }
                
                let routeCoordinates = routeCoordinatesArray.compactMap { coord -> CLLocationCoordinate2D? in
                    guard let lat = coord["latitude"], let lon = coord["longitude"] else { return nil }
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                
                let run = RunData(date: timestamp, distance: distance, elapsedTime: elapsedTime, routeCoordinates: routeCoordinates)
                
                let post = Post(
                    id: postId,
                    ownerUid: userId,
                    caption: postData["caption"] as? String ?? "",
                    likes: likes,
                    imageUrl: "",
                    timestamp: timestamp,
                    user: User(id: userId, username: username, email: ""), // You may fetch email if required
                    runData: run
                )
                
                fetchedPosts.append(post)
            }
            
            DispatchQueue.main.async {
                self.posts = fetchedPosts
                print("DEBUG: Total posts loaded: \(self.posts.count)")
            }
            
        } catch {
            print("DEBUG: Failed to fetch posts with error \(error.localizedDescription)")
        }
    }
}

