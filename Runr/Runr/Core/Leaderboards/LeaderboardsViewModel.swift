//
//  LeaderboardsViewModel.swift
//  Runr
//
//  Created by Noah Moran on 15/1/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct LeaderUser: Identifiable {
    var id: String
    var name: String
    var totalDistance: Double
    var imageUrl: String
}

class LeaderboardViewModel: ObservableObject {
    @Published var users: [LeaderUser] = []
    
    func fetchLeaderboard() {
        let db = Firestore.firestore()
        
        db.collection("users")
            .order(by: "totalDistance", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {  // Ensure UI updates happen on main thread
                    if let error = error {
                        print("DEBUG: Failed to fetch leaderboard with error \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("DEBUG: No documents found")
                        return
                    }
                    
                    self.users = documents.compactMap { doc -> LeaderUser? in
                        let data = doc.data()
                        guard
                            let username = data["username"] as? String,
                            let totalDistance = data["totalDistance"] as? Double else { return nil }
                        
                        let profileImageUrl = data["profileImageUrl"] as? String ?? "https://example.com/default-profile.jpg"
                        
                        return LeaderUser(id: doc.documentID, name: username, totalDistance: totalDistance, imageUrl: profileImageUrl)
                    }
                }
            }
    }
}
