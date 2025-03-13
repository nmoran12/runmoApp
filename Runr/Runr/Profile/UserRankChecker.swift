//
//  UserRankChecker.swift
//  Runr
//
//  Created by Noah Moran on 12/3/2025.
//

import SwiftUI
import FirebaseFirestore

class UserRankChecker: ObservableObject {
    @Published var isFirst = false

    func checkIfUserIsFirst(userId: String) async {
        let db = Firestore.firestore()

        do {
            let snapshot = try await db.collection("users")
                .order(by: "totalDistance", descending: true)
                .getDocuments()

            DispatchQueue.main.async {
                let leaderboardUsers = snapshot.documents.compactMap { doc -> String? in
                    return doc.documentID // Get user ID only
                }

                if let firstUserId = leaderboardUsers.first {
                    self.isFirst = firstUserId == userId
                    print("DEBUG: isFirst set to \(self.isFirst)")
                }
            }
        } catch {
            print("DEBUG: Failed to fetch leaderboard \(error.localizedDescription)")
        }
    }
}
