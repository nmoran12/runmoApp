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
    
    // New: store conversationId
    var conversationId: String = ""

    func loadMessages(conversationId: String) {
        guard !conversationId.isEmpty else {
            print("DEBUG: conversationId is empty! Cannot load messages.")
            return
        }
        self.conversationId = conversationId  // store it for later use
        db.collection("conversations").document(conversationId).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.messages = documents.compactMap { doc -> Message? in
                    try? doc.data(as: Message.self)
                }
            }
    }

    func sendMessage(conversationId: String, text: String) {
        let messageId = UUID().uuidString
        let message = Message(
            id: messageId,
            senderId: currentUserId,
            text: text,
            timestamp: Date(),
            reactions: [:]
        )

        // Use the same messageId as the document ID
        let ref = db.collection("conversations")
                    .document(conversationId)
                    .collection("messages")
                    .document(messageId)
        
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
    
    // New: Add reaction to a message
    func addReaction(to message: Message, reaction: String) {
        let messageRef = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(message.id)
        
        // Update the current user's reaction without overwriting others.
        messageRef.updateData(["reactions.\(currentUserId)" : reaction]) { error in
            if let error = error {
                print("Error updating reaction: \(error)")
            } else {
                if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                    var updatedReactions = self.messages[index].reactions ?? [:]
                    updatedReactions[self.currentUserId] = reaction
                    self.messages[index].reactions = updatedReactions
                }
            }
        }
    }


}

#Preview {
    Text("Chat View Model Preview")
}

