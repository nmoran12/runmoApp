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

enum LeaderboardScope: String, CaseIterable, Identifiable {
    case local = "Local"
    case national = "National"
    case global = "Global"
    
    var id: String { self.rawValue }
}


struct LeaderUser: Identifiable, Equatable {
    var id: String
    var name: String
    var score: Double    // Represents total distance (km) or fastest 5K time (seconds)
    var imageUrl: String
}

extension LeaderUser {
    static let MOCK_USER = LeaderUser(
        id: "1",
        name: "Mock User",
        score: 42.5,  // Changed from totalDistance to score
        imageUrl: "https://example.com/default-profile.jpg"
    )
}

// if you ever want to add more leaderboards to the leaderboard, you must update this as well
extension LeaderUser {
    func displayValue(for type: LeaderboardType) -> String {
        switch type {
        case .fastest5k, .fastest10k, .fastestHalfMarathon, .fastestMarathon:
            // Convert seconds to a time string. This implementation uses mm:ss.
            // If the time might exceed an hour, you can add hours as needed.
            let totalSeconds = self.score
            let hours = Int(totalSeconds) / 3600
            let minutes = (Int(totalSeconds) % 3600) / 60
            let seconds = Int(totalSeconds) % 60
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        case .totalDistance:
            return String(format: "%.2f km", self.score)
        }
    }
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
                                              score: totalDistance,
                                              imageUrl: profileImageUrl)
                        }
                    }
                }
            }
    }
    
    // This is for a time-based fetch (weekly, monthly, yearly)
    func fetchLeaderboard(for period: LeaderboardPeriod, scope: LeaderboardScope) {
        let db = Firestore.firestore()
        let startDate = period.startDate

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
                
                var userDistanceMap: [String: Double] = [:]
                
                for doc in documents {
                    let data = doc.data()
                    guard let distance = data["distance"] as? Double else { continue }
                    guard let userId = doc.reference.parent.parent?.documentID else { continue }
                    userDistanceMap[userId, default: 0] += distance
                }
                
                let userIds = Array(userDistanceMap.keys)
                if userIds.isEmpty {
                    DispatchQueue.main.async {
                        self.users = []
                    }
                    return
                }
                
                // Begin building the user query
                var userQuery = db.collection("users")
                    .whereField(FieldPath.documentID(), in: userIds)
                
                // Add location filtering based on scope:
                switch scope {
                case .local:
                    if let currentCity = AuthService.shared.currentUser?.city {
                        userQuery = userQuery.whereField("city", isEqualTo: currentCity)
                    }
                case .national:
                    if let currentIso = AuthService.shared.currentUser?.isoCountryCode {
                        userQuery = userQuery.whereField("isoCountryCode", isEqualTo: currentIso)
                    }
                case .global:
                    break // no additional filter
                }
                
                userQuery.getDocuments { userSnapshot, userError in
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
                        let score = distanceSum / 1000  // in kilometers
                        
                        let leaderUser = LeaderUser(
                            id: userDoc.documentID,
                            name: username,
                            score: score,
                            imageUrl: profileImageUrl
                        )
                        leaderboard.append(leaderUser)
                    }
                    
                    // Sort descending by score
                    leaderboard.sort { $0.score > $1.score }
                    
                    DispatchQueue.main.async {
                        withAnimation {
                            self.users = leaderboard
                        }
                    }
                }
            }
    }

    
    // For Fastest 10K (10,000 meters)
    func fetchFastest10kLeaderboard(for period: LeaderboardPeriod) {
        let db = Firestore.firestore()
        let startDate = period.startDate
        let targetDistance = 10_000.0

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
                
                var userBestTimeMap: [String: Double] = [:]
                for doc in documents {
                    let data = doc.data()
                    guard let distance = data["distance"] as? Double, distance >= targetDistance,
                          let elapsedTime = data["elapsedTime"] as? Double else { continue }
                    
                    let equivalentTime = elapsedTime * (targetDistance / distance)
                    
                    guard let userId = doc.reference.parent.parent?.documentID else { continue }
                    
                    if let currentBest = userBestTimeMap[userId] {
                        userBestTimeMap[userId] = min(currentBest, equivalentTime)
                    } else {
                        userBestTimeMap[userId] = equivalentTime
                    }
                }
                
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
                            
                            let bestTime = userBestTimeMap[userDoc.documentID] ?? 0
                            
                            let leaderUser = LeaderUser(
                                id: userDoc.documentID,
                                name: username,
                                score: bestTime,  // Fastest 10K time in seconds
                                imageUrl: profileImageUrl
                            )
                            leaderboard.append(leaderUser)
                        }
                        
                        leaderboard.sort { $0.score < $1.score }
                        
                        DispatchQueue.main.async {
                            withAnimation {
                                self.users = leaderboard
                            }
                        }
                    }
            }
    }

    // For Fastest Half-Marathon (21,097.5 meters)
    func fetchFastestHalfMarathonLeaderboard(for period: LeaderboardPeriod) {
        let db = Firestore.firestore()
        let startDate = period.startDate
        let targetDistance = 21_097.5

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
                
                var userBestTimeMap: [String: Double] = [:]
                for doc in documents {
                    let data = doc.data()
                    guard let distance = data["distance"] as? Double, distance >= targetDistance,
                          let elapsedTime = data["elapsedTime"] as? Double else { continue }
                    
                    let equivalentTime = elapsedTime * (targetDistance / distance)
                    
                    guard let userId = doc.reference.parent.parent?.documentID else { continue }
                    
                    if let currentBest = userBestTimeMap[userId] {
                        userBestTimeMap[userId] = min(currentBest, equivalentTime)
                    } else {
                        userBestTimeMap[userId] = equivalentTime
                    }
                }
                
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
                            
                            let bestTime = userBestTimeMap[userDoc.documentID] ?? 0
                            
                            let leaderUser = LeaderUser(
                                id: userDoc.documentID,
                                name: username,
                                score: bestTime,  // Fastest Half-Marathon time in seconds
                                imageUrl: profileImageUrl
                            )
                            leaderboard.append(leaderUser)
                        }
                        
                        leaderboard.sort { $0.score < $1.score }
                        
                        DispatchQueue.main.async {
                            withAnimation {
                                self.users = leaderboard
                            }
                        }
                    }
            }
    }

    // For Fastest Marathon (42,195 meters)
    func fetchFastestMarathonLeaderboard(for period: LeaderboardPeriod) {
        let db = Firestore.firestore()
        let startDate = period.startDate
        let targetDistance = 42_195.0

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
                
                var userBestTimeMap: [String: Double] = [:]
                for doc in documents {
                    let data = doc.data()
                    guard let distance = data["distance"] as? Double, distance >= targetDistance,
                          let elapsedTime = data["elapsedTime"] as? Double else { continue }
                    
                    let equivalentTime = elapsedTime * (targetDistance / distance)
                    
                    guard let userId = doc.reference.parent.parent?.documentID else { continue }
                    
                    if let currentBest = userBestTimeMap[userId] {
                        userBestTimeMap[userId] = min(currentBest, equivalentTime)
                    } else {
                        userBestTimeMap[userId] = equivalentTime
                    }
                }
                
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
                            
                            let bestTime = userBestTimeMap[userDoc.documentID] ?? 0
                            
                            let leaderUser = LeaderUser(
                                id: userDoc.documentID,
                                name: username,
                                score: bestTime,  // Fastest Marathon time in seconds
                                imageUrl: profileImageUrl
                            )
                            leaderboard.append(leaderUser)
                        }
                        
                        leaderboard.sort { $0.score < $1.score }
                        
                        DispatchQueue.main.async {
                            withAnimation {
                                self.users = leaderboard
                            }
                        }
                    }
            }
    }

    
    // this is a generic function that works to fetch the fastest time of any distance you parse into it
    func fetchFastestLeaderboard(for period: LeaderboardPeriod,
                                 targetDistance: Double,
                                 scope: LeaderboardScope) {
        let db = Firestore.firestore()
        let startDate = period.startDate
        
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
                
                var userBestTimeMap: [String: Double] = [:]
                for doc in documents {
                    let data = doc.data()
                    guard let distance = data["distance"] as? Double, distance >= targetDistance,
                          let elapsedTime = data["elapsedTime"] as? Double else { continue }
                    
                    let equivalentTime = elapsedTime * (targetDistance / distance)
                    guard let userId = doc.reference.parent.parent?.documentID else { continue }
                    
                    if let currentBest = userBestTimeMap[userId] {
                        userBestTimeMap[userId] = min(currentBest, equivalentTime)
                    } else {
                        userBestTimeMap[userId] = equivalentTime
                    }
                }
                
                let userIds = Array(userBestTimeMap.keys)
                if userIds.isEmpty {
                    DispatchQueue.main.async {
                        self.users = []
                    }
                    return
                }
                
                // Build the user query
                var userQuery = db.collection("users")
                    .whereField(FieldPath.documentID(), in: userIds)
                
                // Filter by city or isoCountryCode if scope is local/national
                switch scope {
                case .local:
                    if let currentCity = AuthService.shared.currentUser?.city {
                        userQuery = userQuery.whereField("city", isEqualTo: currentCity)
                    }
                case .national:
                    if let currentIso = AuthService.shared.currentUser?.isoCountryCode {
                        userQuery = userQuery.whereField("isoCountryCode", isEqualTo: currentIso)
                    }
                case .global:
                    break
                }
                
                userQuery.getDocuments { userSnapshot, userError in
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
                        
                        let bestTime = userBestTimeMap[userDoc.documentID] ?? 0
                        let leaderUser = LeaderUser(
                            id: userDoc.documentID,
                            name: username,
                            score: bestTime,  // Fastest time in seconds
                            imageUrl: profileImageUrl
                        )
                        leaderboard.append(leaderUser)
                    }
                    
                    // Sort ascending by time (faster = smaller value)
                    leaderboard.sort { $0.score < $1.score }
                    
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
                
                var userBestTimeMap: [String: Double] = [:]
                for doc in documents {
                    let data = doc.data()
                    
                    guard let distance = data["distance"] as? Double, distance >= 5000 else { continue }
                    guard let duration = data["elapsedTime"] as? Double else { continue }
                    
                    let fiveKTime = duration * (5000 / distance)
                    
                    guard let userId = doc.reference.parent.parent?.documentID else { continue }
                    
                    if let currentBest = userBestTimeMap[userId] {
                        userBestTimeMap[userId] = min(currentBest, fiveKTime)
                    } else {
                        userBestTimeMap[userId] = fiveKTime
                    }
                }
                
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
                            
                            let bestFiveKTime = userBestTimeMap[userDoc.documentID] ?? 0
                            
                            let leaderUser = LeaderUser(
                                id: userDoc.documentID,
                                name: username,
                                score: bestFiveKTime,  // Fastest 5K time in seconds
                                imageUrl: profileImageUrl
                            )
                            leaderboard.append(leaderUser)
                        }
                        
                        leaderboard.sort { $0.score < $1.score }
                        
                        DispatchQueue.main.async {
                            withAnimation {
                                self.users = leaderboard
                            }
                        }
                    }
            }
    }
}
