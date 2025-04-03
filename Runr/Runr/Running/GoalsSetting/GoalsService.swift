//
//  GoalsService.swift
//  Runr
//
//  Created by Noah Moran on 3/4/2025.
//

import FirebaseFirestore
import FirebaseAuth

// This function is used to uploaded goals that a user selects to google firebase
func uploadUserGoals(goals: [Goal]) async {
    guard let userId = Auth.auth().currentUser?.uid else {
        print("No user logged in.")
        return
    }
    
    let db = Firestore.firestore()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "ddMMyy-HHmmss" // Format without slashes for safety in document IDs
    
    for goal in goals {
        let dateStamp = dateFormatter.string(from: Date())
        let documentId = "\(dateStamp)-\(goal.title)" // e.g., "290423-134501-Weekly Distance"
        
        let goalData: [String: Any] = [
            "title": goal.title,
            "target": goal.target,
            "category": goal.category,
            "timestamp": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("goals")
                .document(documentId)
                .setData(goalData)
            print("Goal \(goal.title) uploaded successfully with document ID: \(documentId)")
        } catch {
            print("Error uploading goal \(goal.title): \(error.localizedDescription)")
        }
    }
}

// This is used to fetch user's goals from google firebase to display them
func fetchUserGoals() async -> [Goal] {
    guard let userId = AuthService.shared.userSession?.uid else {
        print("No user logged in.")
        return []
    }
    
    let db = Firestore.firestore()
    
    do {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("goals")
            .getDocuments()
        
        let goals: [Goal] = snapshot.documents.compactMap { document in
            let data = document.data()
            guard let title = data["title"] as? String,
                  let target = data["target"] as? String,
                  let category = data["category"] as? String else {
                return nil
            }
            
            var goal = Goal(title: title, category: category)
            goal.target = target
            return goal
        }
        return goals
    } catch {
        print("Error fetching goals: \(error.localizedDescription)")
        return []
    }
}
