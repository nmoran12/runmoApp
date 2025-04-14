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

    // Optional footwear filter.
    let footwear: String?

    // Initialize with an optional footwear filter.
    init(footwear: String? = nil) {
        self.footwear = footwear
    }

    // Fetch posts or, if filtering by footwear, fetch runs from the user's runs subcollection.
    func fetchPosts(initial: Bool = false) async {
        guard !isFetching else { return }
        isFetching = true

        if initial {
            noMorePosts = false
            lastDocument = nil
            posts = []
        }
        
        // If we have a footwear filter, query the runs subcollection.
        if let footwear = footwear {
            guard let userId = AuthService.shared.userSession?.uid else {
                isFetching = false
                return
            }
            
            // Query the "runs" subcollection for runs with the given footwear.
            var query: Query = Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("runs")
                .whereField("footwear", isEqualTo: footwear)
                .order(by: "timestamp", descending: true)
                .limit(to: 10)
            
            // Use lastDocument for pagination, if available.
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
                for runDoc in runsSnapshot.documents {
                    let data = runDoc.data()
                    
                    // Use the run document's ID as the Post id.
                    let postId = runDoc.documentID
                    // Extract common run data.
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let distance = data["distance"] as? Double ?? 0.0
                    let elapsedTime = data["elapsedTime"] as? Double ?? 0.0
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
                    
                    // Build a Post object. We assume these runs are your own,
                    // so ownerUid is the current user and caption, likes, etc., can be defaulted.
                    let post = Post(
                        id: postId,
                        ownerUid: userId,
                        caption: "", // No caption by default.
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
        
        // Otherwise (if no footwear filter provided), query the posts collection as before.
        var query: Query = Firestore.firestore().collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
        
        if !initial, let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        do {
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
                
                // Fetch run data (if needed) from the corresponding run document.
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
                    guard
                        let lat = dict["latitude"] as? Double,
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
            print("DEBUG: Failed to fetch posts with error \(error.localizedDescription)")
        }
        
        isFetching = false
    }
    
    func refreshFeed() async {
        lastDocument = nil
        await fetchPosts(initial: true)
    }
}
