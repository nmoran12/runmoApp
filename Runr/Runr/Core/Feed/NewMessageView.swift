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
            return users.filter {
                $0.username.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar at the top
                TextField("Search", text: $searchText)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // List of filtered users
                List {
                    ForEach(filteredUsers) { user in
                        Button {
                            startNewConversation(with: user)
                        } label: {
                            userRow(user)
                        }
                        .padding(.vertical, 4)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
            }
            // Custom Nav Bar
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Title on the left
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("New Message")
                        .font(.system(size: 18, weight: .semibold))
                }
                // Cancel button on the right
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(size: 16))
                }
            }
            .onAppear {
                fetchUsers()
            }
        }
    }

    // MARK: - User Row
    @ViewBuilder
    private func userRow(_ user: User) -> some View {
        HStack(spacing: 12) {
            // Profile image (placeholder)
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            Text(user.username)
                .font(.system(size: 16, weight: .medium))

            Spacer()
        }
    }

    // MARK: - Fetch Users
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
                guard
                    let username = data["username"] as? String,
                    let id = data["id"] as? String,
                    let email = data["email"] as? String,
                    id != currentUserId  // Exclude current user
                else { return nil }
                return User(id: id, username: username, email: email)
            } ?? []
        }
    }

    // MARK: - Start Conversation
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

