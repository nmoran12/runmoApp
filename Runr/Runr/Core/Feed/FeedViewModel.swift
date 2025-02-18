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
        print("DEBUG: Fetching runs from all users...")

        do {
            let usersSnapshot = try await Firestore.firestore().collection("users").getDocuments()
            
            var fetchedPosts: [Post] = []

            for userDoc in usersSnapshot.documents {
                let userData = userDoc.data()
                guard
                    let userId = userData["id"] as? String,
                    let username = userData["username"] as? String,
                    let email = userData["email"] as? String
                else {
                    print("DEBUG: Skipping user due to missing fields")
                    continue
                }

                let user = User(id: userId, username: username, email: email)

                // Fetch user's runs
                let runsSnapshot = try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .collection("runs")
                    .order(by: "date", descending: true)
                    .getDocuments()

                for runDoc in runsSnapshot.documents {
                    let runData = runDoc.data()

                    guard
                        let date = (runData["date"] as? Timestamp)?.dateValue(),
                        let distance = runData["distance"] as? Double,
                        let elapsedTime = runData["elapsedTime"] as? Double,
                        let routeCoordinatesArray = runData["routeCoordinates"] as? [[String: Double]]
                    else {
                        print("DEBUG: Skipping run due to missing fields")
                        continue
                    }

                    // Convert route coordinates
                    let routeCoordinates = routeCoordinatesArray.compactMap { coord -> CLLocationCoordinate2D? in
                        guard let lat = coord["latitude"], let lon = coord["longitude"] else { return nil }
                        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }

                    let run = RunData(date: date, distance: distance, elapsedTime: elapsedTime, routeCoordinates: routeCoordinates)

                    // Store the run data inside the posts collection
                    let postRef = Firestore.firestore().collection("posts").document(runDoc.documentID)
                    
                    let postSnapshot = try? await postRef.getDocument()
                    let existingLikes = postSnapshot?.data()?["likes"] as? Int ?? 0

                    let postData: [String: Any] = [
                        "id": runDoc.documentID,
                        "ownerUid": userId,
                        "username": username,
                        "email": email,
                        "timestamp": date,
                        "runData": [
                            "distance": distance,
                            "elapsedTime": elapsedTime,
                            "routeCoordinates": routeCoordinates.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
                        ],
                        "likes": existingLikes,
                        "caption": "\(username)'s run - \(String(format: "%.2f km", distance))"
                    ]
                    
                    try await postRef.setData(postData, merge: true)
                    
                    let post = Post(
                        id: runDoc.documentID,
                        ownerUid: userId,
                        caption: "\(username)'s run - \(String(format: "%.2f km", distance))",
                        likes: 0,
                        imageUrl: "",
                        timestamp: date,
                        user: user,
                        runData: run
                    )

                    fetchedPosts.append(post)
                }
            }

            // Sort all fetched posts by timestamp (most recent first)
            fetchedPosts.sort { $0.timestamp > $1.timestamp }

            DispatchQueue.main.async {
                self.posts = fetchedPosts
                print("DEBUG: Total posts loaded: \(self.posts.count) in sorted order")
            }

        } catch {
            print("DEBUG: Failed to fetch runs with error \(error.localizedDescription)")
        }
    }
}

