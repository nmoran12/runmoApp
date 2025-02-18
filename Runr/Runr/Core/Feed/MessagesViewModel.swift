//
//  MessagesViewModel.swift
//  Runr
//
//  Created by Noah Moran on 11/2/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct Conversation: Identifiable, Codable {
    var id: String
    var users: [String] // User IDs
    var lastMessage: Message?
    
    var otherUserId: String? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        return users.first { $0 != currentUserId }
    }
    
    var otherUserName: String?
}


struct Message: Identifiable, Codable {
    var id: String
    var senderId: String
    var text: String
    @ServerTimestamp var timestamp: Date?
}


class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    
    private let db = Firestore.firestore()
    
    func fetchConversations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("conversations")
            .whereField("users", arrayContains: currentUserId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                var conversations = documents.compactMap { doc -> Conversation? in
                    try? doc.data(as: Conversation.self)
                }
                
                let group = DispatchGroup()
                
                for i in 0..<conversations.count {
                    if let otherUserId = conversations[i].otherUserId {
                        group.enter()
                        self.fetchUsername(for: otherUserId) { username in
                            conversations[i].otherUserName = username
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    // Sort conversations by lastMessage timestamp (most recent first)
                    self.conversations = conversations.sorted {
                        ($0.lastMessage?.timestamp ?? Date.distantPast) > ($1.lastMessage?.timestamp ?? Date.distantPast)
                    }
                }
            }
    }


    
    private func fetchUsername(for userId: String, completion: @escaping (String) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists, let data = document.data(),
               let username = data["username"] as? String {
                completion(username)
            } else {
                completion("Unknown User")
            }
        }
    }
}


#Preview {
    Text("Messages ViewModel Preview")
}

