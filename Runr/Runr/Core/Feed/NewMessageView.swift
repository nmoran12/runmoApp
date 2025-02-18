//
//  NewMessagesView.swift
//  Runr
//
//  Created by Noah Moran on 11/2/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NewMessageView: View {
    @Binding var isPresented: Bool
    @State private var users: [User] = []
    @State private var searchText = ""

    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { $0.username.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search users", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                List(filteredUsers) { user in
                    Button(action: {
                        startNewConversation(with: user)
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())

                            Text(user.username)
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 5)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("New Message")
            .navigationBarItems(trailing:
                Button("Cancel") {
                    isPresented = false
                }
            )
            .onAppear {
                fetchUsers()
            }
        }
    }

    private func fetchUsers() {
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("DEBUG: Failed to fetch users \(error.localizedDescription)")
                return
            }

            self.users = snapshot?.documents.compactMap { doc -> User? in
                let data = doc.data()
                guard let username = data["username"] as? String,
                      let id = data["id"] as? String,
                      let email = data["email"] as? String,
                      id != currentUserId else { return nil } // Exclude current user
                return User(id: id, username: username, email: email)
            } ?? []
        }
    }


    private func startNewConversation(with user: User) {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        let db = Firestore.firestore()
        
        let conversationRef = db.collection("conversations").document()
        
        let conversationData: [String: Any] = [
            "id": conversationRef.documentID,
            "users": [currentUserId, user.id]
        ]
        
        conversationRef.setData(conversationData) { error in
            if let error = error {
                print("DEBUG: Failed to create conversation \(error.localizedDescription)")
            } else {
                print("DEBUG: Started conversation with \(user.username)")
                isPresented = false
            }
        }
    }
}

#Preview {
    NewMessageView(isPresented: .constant(false))
}
