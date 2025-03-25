//
//  LeaderboardsViewModel.swift
//  Runr
//
//  Created by Noah Moran on 15/1/2025.
//

import FirebaseFirestore
import SwiftUI

enum LeaderboardPeriod {
    case weekly
    case monthly
    case yearly
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .weekly:
            // Last 7 days
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .monthly:
            // Last 30 days (simple approach) or from the start of the month
            return calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .yearly:
            // Last 365 days or from the start of the year
            return calendar.date(byAdding: .day, value: -365, to: now) ?? now
        }
    }
}

struct LeaderUser: Identifiable, Equatable {
    var id: String
    var name: String
    var totalDistance: Double
    var imageUrl: String
}

extension LeaderUser {
    static let MOCK_USER = LeaderUser(
        id: "1",
        name: "Mock User",
        totalDistance: 42.5,
        imageUrl: "https://example.com/default-profile.jpg"
    )
}

class LeaderboardViewModel: ObservableObject {
    @Published var users: [LeaderUser] = []
    
    // This is for your "all-time" fetch
    func fetchLeaderboardAllTime() {
        let db = Firestore.firestore()
        
        db.collection("users")
            .order(by: "totalDistance", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("DEBUG: Failed to fetch leaderboard with error \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No documents found")
                    return
                }
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.users = documents.compactMap { doc -> LeaderUser? in
                            let data = doc.data()
                            guard
                                let username = data["username"] as? String,
                                let totalDistance = data["totalDistance"] as? Double
                            else { return nil }
                            
                            let profileImageUrl = data["profileImageUrl"] as? String ?? ""
                            
                            return LeaderUser(id: doc.documentID,
                                              name: username,
                                              totalDistance: totalDistance,
                                              imageUrl: profileImageUrl)
                        }
                    }
                }
            }
    }
    
    // This is for a time-based fetch (weekly, monthly, yearly)
    func fetchLeaderboard(for period: LeaderboardPeriod) {
        let db = Firestore.firestore()
        
        // 1. Get the startDate for the desired period
        let startDate = period.startDate
        
        // 2. Query runs using a collection group query
        db.collectionGroup("runs")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("DEBUG: Error fetching runs: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No run documents found")
                    return
                }
                
                // 3. Aggregate distances by userId
                var userDistanceMap: [String: Double] = [:]
                
                for doc in documents {
                    let data = doc.data()
                    
                    guard let distance = data["distance"] as? Double else { continue }
                    // Extract userId from the document's parent collection
                    guard let userId = doc.reference.parent.parent?.documentID else { continue }
                    userDistanceMap[userId, default: 0] += distance
                }
                
                // 4. Fetch the user info from the "users" collection using the aggregated userIds
                let userIds = Array(userDistanceMap.keys)
                if userIds.isEmpty {
                    DispatchQueue.main.async {
                        self.users = []
                    }
                    return
                }
                
                db.collection("users")
                    .whereField(FieldPath.documentID(), in: userIds)
                    .getDocuments { userSnapshot, userError in
                        if let userError = userError {
                            print("DEBUG: Error fetching users: \(userError.localizedDescription)")
                            return
                        }
                        
                        guard let userDocs = userSnapshot?.documents else {
                            print("DEBUG: No user documents found")
                            return
                        }
                        
                        var leaderboard: [LeaderUser] = []
                        
                        for userDoc in userDocs {
                            let data = userDoc.data()
                            guard let username = data["username"] as? String else { continue }
                            
                            let profileImageUrl = data["profileImageUrl"] as? String ?? ""
                            let distanceSum = userDistanceMap[userDoc.documentID] ?? 0

                            // Convert meters to kilometers
                            let distanceInKm = distanceSum / 1000

                            let leaderUser = LeaderUser(
                                id: userDoc.documentID,
                                name: username,
                                totalDistance: distanceInKm,  // Use distanceInKm here
                                imageUrl: profileImageUrl
                            )
                            leaderboard.append(leaderUser)
                        }
                        
                        // 5. Sort descending by totalDistance
                        leaderboard.sort { $0.totalDistance > $1.totalDistance }
                        
                        // 6. Update the published property on the main thread
                        DispatchQueue.main.async {
                            withAnimation {
                                self.users = leaderboard
                            }
                        }
                    }
            }
    }
    
    // For the leaderboard that displays the fastest 5k's in a time period
    func fetchFastest5kLeaderboard(for period: LeaderboardPeriod) {
        let db = Firestore.firestore()
        let startDate = period.startDate

        // 1. Query runs in the selected period.
        db.collectionGroup("runs")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("DEBUG: Error fetching runs: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No run documents found")
                    return
                }
                
                // 2. For each run, filter out those below 5km and compute the 5k equivalent time.
                var userBestTimeMap: [String: Double] = [:]
                for doc in documents {
                    let data = doc.data()
                    
                    // Ensure the run is at least 5km.
                    guard let distance = data["distance"] as? Double, distance >= 5000 else { continue }
                    // Assume you have a "duration" field in seconds.
                    guard let duration = data["duration"] as? Double else { continue }
                    
                    // Calculate the 5k equivalent time.
                    let fiveKTime = duration * (5000 / distance)
                    
                    // Get the userId from the document’s parent reference.
                    guard let userId = doc.reference.parent.parent?.documentID else { continue }
                    
                    // Update the best time if this run is faster.
                    if let currentBest = userBestTimeMap[userId] {
                        userBestTimeMap[userId] = min(currentBest, fiveKTime)
                    } else {
                        userBestTimeMap[userId] = fiveKTime
                    }
                }
                
                // 3. Fetch user info for the aggregated user IDs.
                let userIds = Array(userBestTimeMap.keys)
                if userIds.isEmpty {
                    DispatchQueue.main.async {
                        self.users = []
                    }
                    return
                }
                
                db.collection("users")
                    .whereField(FieldPath.documentID(), in: userIds)
                    .getDocuments { userSnapshot, userError in
                        if let userError = userError {
                            print("DEBUG: Error fetching users: \(userError.localizedDescription)")
                            return
                        }
                        
                        guard let userDocs = userSnapshot?.documents else {
                            print("DEBUG: No user documents found")
                            return
                        }
                        
                        var leaderboard: [LeaderUser] = []
                        for userDoc in userDocs {
                            let data = userDoc.data()
                            guard let username = data["username"] as? String else { continue }
                            let profileImageUrl = data["profileImageUrl"] as? String ?? ""
                            // Use the best (lowest) 5k time for this user.
                            let bestFiveKTime = userBestTimeMap[userDoc.documentID] ?? 0
                            
                            // You might consider renaming the property in your model for clarity,
                            // but here we use totalDistance to store the fastest time (in seconds).
                            let leaderUser = LeaderUser(
                                id: userDoc.documentID,
                                name: username,
                                totalDistance: bestFiveKTime,  // Represents fastest 5k time in seconds
                                imageUrl: profileImageUrl
                            )
                            leaderboard.append(leaderUser)
                        }
                        
                        // 4. Sort so that the fastest (lowest time) is at the top.
                        leaderboard.sort { $0.totalDistance < $1.totalDistance }
                        
                        // 5. Update your UI on the main thread.
                        DispatchQueue.main.async {
                            withAnimation {
                                self.users = leaderboard
                            }
                        }
                    }
            }
    }

    
}
