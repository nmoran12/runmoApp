//
//  ChatViewModel.swift
//  Runr
//
//  Created by Noah Moran on 11/2/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserProfile: Identifiable, Codable {
    let id: String
    let realName: String
    let username: String
    let email: String
    let averagePace: Double
    let totalTime: Double
    let totalDistance: Double
}


class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var userProfile: UserProfile?

    let currentUserId = Auth.auth().currentUser?.uid ?? ""
    private let db = Firestore.firestore()

    func loadMessages(conversationId: String) {
        db.collection("conversations").document(conversationId).collection("messages")
            .order(by: "timestamp", descending: false) // Change to ascending order
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self.messages = documents.compactMap { doc -> Message? in
                    try? doc.data(as: Message.self)
                }
            }
    }



    func sendMessage(conversationId: String, text: String) {
        let message = Message(
            id: UUID().uuidString,
            senderId: currentUserId,
            text: text,
            timestamp: Date()
        )

        let ref = db.collection("conversations").document(conversationId).collection("messages").document()
        
        do {
            try ref.setData(from: message)
        } catch {
            print("Error sending message: \(error)")
        }
    }

    func loadUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user profile: \(error)")
                return
            }
            guard let document = snapshot, document.exists else {
                print("No user profile found for ID: \(userId)")
                return
            }
            do {
                let data = document.data()
                let user = UserProfile(
                    id: data?["id"] as? String ?? "",
                    realName: data?["realName"] as? String ?? "Unknown",
                    username: data?["username"] as? String ?? "",
                    email: data?["email"] as? String ?? "",
                    averagePace: data?["averagePace"] as? Double ?? 0.0,
                    totalTime: data?["totalTime"] as? Double ?? 0.0,
                    totalDistance: data?["totalDistance"] as? Double ?? 0.0
                )
                self.userProfile = user
                print("User profile loaded: \(self.userProfile!)")
            } catch {
                print("Error decoding user profile: \(error)")
            }
        }
    }

}




#Preview {
    Text("Chat View Model Preview")
}

