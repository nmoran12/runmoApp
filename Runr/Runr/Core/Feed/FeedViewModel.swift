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

    // If non-nil, we are filtering by footwear; this branch fetches the current user's runs.
    // When nil, we fetch the feed of posts from users that the current user follows.
    let footwear: String?

    init(footwear: String? = nil) {
        self.footwear = footwear
    }

    func fetchPosts(initial: Bool = false) async {
        guard !isFetching else { return }
        isFetching = true

        if initial {
            noMorePosts = false
            lastDocument = nil
            posts = []
        }
        
        // --------- Branch 1: Filter by Footwear for Current User's Runs ---------
        if let footwear = footwear {
            // Ensure we have the current user's UID.
            guard let userId = AuthService.shared.userSession?.uid else {
                isFetching = false
                return
            }
            
            // Query the "runs" subcollection for runs that have the specific footwear.
            var query: Query = Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("runs")
                .whereField("footwear", isEqualTo: footwear)
                .order(by: "timestamp", descending: true)
                .limit(to: 10)
            
            if !initial, let lastDoc = lastDocument {
                query = query.start(afterDocument: lastDoc)
            }
            
            do {
                let runsSnapshot = try await query.getDocuments()
                if runsSnapshot.documents.isEmpty {
                    noMorePosts = true
                    isFetching = false
                    return
                }
                lastDocument = runsSnapshot.documents.last
                
                var fetchedPosts: [Post] = []
                // Convert each run document into a Post object.
                for runDoc in runsSnapshot.documents {
                    let data = runDoc.data()
                    
                    // Use the run document's ID as the post ID.
                    let postId = runDoc.documentID
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let distance = data["distance"] as? Double ?? 0.0
                    let elapsedTime = data["elapsedTime"] as? Double ?? 0.0
                    
                    // Convert the coordinates array.
                    let routeCoordinatesArray = data["routeCoordinates"] as? [[String: Any]] ?? []
                    let routeCoordinates = routeCoordinatesArray.compactMap { dict -> CLLocationCoordinate2D? in
                        guard let lat = dict["latitude"] as? Double,
                              let lon = dict["longitude"] as? Double
                        else { return nil }
                        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                    
                    let run = RunData(
                        date: timestamp,
                        distance: distance,
                        elapsedTime: elapsedTime,
                        routeCoordinates: routeCoordinates
                    )
                    
                    // Since these are current user's runs, you can set the post's owner information accordingly.
                    let post = Post(
                        id: postId,
                        ownerUid: userId,
                        caption: "",
                        likes: 0,
                        imageUrl: "",
                        timestamp: timestamp,
                        user: User(id: userId, username: "You", email: ""),
                        runData: run
                    )
                    fetchedPosts.append(post)
                }
                
                DispatchQueue.main.async {
                    if initial {
                        self.posts = fetchedPosts
                    } else {
                        self.posts.append(contentsOf: fetchedPosts)
                    }
                }
            } catch {
                print("DEBUG: Failed to fetch runs with error \(error.localizedDescription)")
            }
            
            isFetching = false
            return
        }
        
        // --------- Branch 2: Filter Feed by Followed Users ---------
        // Instead of referencing a non-existent 'following' property on the user,
        // we fetch the list of followed IDs from Firestore each time:
        do {
            let followedIds = try await AuthService.shared.fetchFollowingList()
            
            // If the current user isn't following anyone, display an empty feed.
            guard !followedIds.isEmpty else {
                DispatchQueue.main.async {
                    self.posts = []
                    self.noMorePosts = true
                }
                isFetching = false
                return
            }
            
            // IMPORTANT: Firestore’s "in" operator only supports up to 10 values.
            // If the current user follows more than 10 people, you'll need to split the array into batches.
            var query: Query = Firestore.firestore().collection("posts")
                .whereField("ownerUid", in: followedIds)
                .order(by: "timestamp", descending: true)
                .limit(to: 10)
            
            if !initial, let lastDoc = lastDocument {
                query = query.start(afterDocument: lastDoc)
            }
            
            let postsSnapshot = try await query.getDocuments()
            if postsSnapshot.documents.isEmpty {
                noMorePosts = true
                isFetching = false
                return
            }
            
            lastDocument = postsSnapshot.documents.last
            var fetchedPosts: [Post] = []
            
            for postDoc in postsSnapshot.documents {
                let postData = postDoc.data()
                guard
                    let postId = postData["id"] as? String,
                    let userId = postData["ownerUid"] as? String,
                    let username = postData["username"] as? String,
                    let runId = postData["runId"] as? String,
                    let likes = postData["likes"] as? Int,
                    let postTimestamp = (postData["timestamp"] as? Timestamp)?.dateValue()
                else {
                    print("DEBUG: Skipping post due to missing fields -> \(postData)")
                    continue
                }
                
                // Fetch associated run data from the posted run.
                let userRef = Firestore.firestore().collection("users").document(userId)
                let runRef = userRef.collection("runs").document(runId)
                let runSnapshot = try? await runRef.getDocument()
                guard
                    let runData = runSnapshot?.data(),
                    let distance = runData["distance"] as? Double,
                    let elapsedTime = runData["elapsedTime"] as? Double,
                    let routeCoordinatesArray = runData["routeCoordinates"] as? [[String: Any]]
                else {
                    print("DEBUG: Skipping run due to missing fields (routeCoordinates)")
                    continue
                }
                
                let routeCoordinates = routeCoordinatesArray.compactMap { dict -> CLLocationCoordinate2D? in
                    guard let lat = dict["latitude"] as? Double,
                          let lon = dict["longitude"] as? Double
                    else { return nil }
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                
                let run = RunData(
                    date: postTimestamp,
                    distance: distance,
                    elapsedTime: elapsedTime,
                    routeCoordinates: routeCoordinates
                )
                
                let post = Post(
                    id: postId,
                    ownerUid: userId,
                    caption: postData["caption"] as? String ?? "",
                    likes: likes,
                    imageUrl: "",
                    timestamp: postTimestamp,
                    user: User(id: userId, username: username, email: ""),
                    runData: run
                )
                fetchedPosts.append(post)
            }
            
            DispatchQueue.main.async {
                if initial {
                    self.posts = fetchedPosts
                } else {
                    self.posts.append(contentsOf: fetchedPosts)
                }
            }
        } catch {
            print("DEBUG: Failed to fetch feed posts with error \(error.localizedDescription)")
        }
        
        isFetching = false
    }
    
    func refreshFeed() async {
        lastDocument = nil
        await fetchPosts(initial: true)
    }
}
