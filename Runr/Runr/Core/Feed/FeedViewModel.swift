//
//  FeedViewModel.swift
//  Runr
//
//  Created by Noah Moran on 13/3/2025.
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
    private var lastDocument: DocumentSnapshot?
    @Published var isFetching = false
    @Published var noMorePosts = false

    // Fetch initial posts or next batch if not initial
    func fetchPosts(initial: Bool = false) async {
        // Prevent duplicate fetches if one is already in progress.
        guard !isFetching else { return }
        isFetching = true
        
        // If this is an initial load or a "refresh," reset everything
                if initial {
                    noMorePosts = false
                    lastDocument = nil
                    posts = []
                }
        
        var query: Query = Firestore.firestore().collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: 10) // Load 10 posts at a time
        
        // If not the initial load, start after the last document of previous batch
        if !initial, let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        do {
            let postsSnapshot = try await query.getDocuments()
            
            // If no more documents are available, set noMorePosts = true
                        if postsSnapshot.documents.isEmpty {
                            noMorePosts = true
                            isFetching = false
                            return
                        }
            
            // Update the last document reference for pagination.
            lastDocument = postsSnapshot.documents.last
            
            var fetchedPosts: [Post] = []
            
            for postDoc in postsSnapshot.documents {
                let postData = postDoc.data()
                // Unpack post fields – adjust as needed for your data
                guard
                    let postId = postData["id"] as? String,
                    let userId = postData["ownerUid"] as? String,
                    let username = postData["username"] as? String,
                    let runId = postData["runId"] as? String,
                    let likes = postData["likes"] as? Int,
                    let timestamp = (postData["timestamp"] as? Timestamp)?.dateValue()
                else {
                    print("DEBUG: Skipping post due to missing fields -> \(postData)")
                    continue
                }
                
                // Optionally, fetch run data as before – if possible, denormalize to avoid extra round trips.
                let userRef = Firestore.firestore().collection("users").document(userId)
                let runRef = userRef.collection("runs").document(runId)
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
                    user: User(id: userId, username: username, email: ""),
                    runData: run
                )
                
                fetchedPosts.append(post)
            }
            
            // Append new posts to the existing list
            DispatchQueue.main.async {
                if initial {
                    self.posts = fetchedPosts
                } else {
                    self.posts.append(contentsOf: fetchedPosts)
                }
            }
            
        } catch {
            print("DEBUG: Failed to fetch posts with error \(error.localizedDescription)")
        }
        
        isFetching = false
    }
    
    // Optionally, a method to refresh the feed
    func refreshFeed() async {
        lastDocument = nil
        await fetchPosts(initial: true)
    }
}

