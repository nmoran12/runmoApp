//
//  CommentsView.swift
//  Runr
//
//  Created by Noah Moran on 6/2/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct CommentsView: View {
    var post: Post
    
    @State private var comments: [Comment] = []
    @State private var newComment: String = ""
    
    func fetchComments() {
        let commentsRef = Firestore.firestore()
            .collection("posts")
            .document(post.id)
            .collection("comments")
            .order(by: "timestamp", descending: true)
        
        commentsRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching comments: \(error.localizedDescription)")
                return
            }
            
            self.comments = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                return Comment(
                    id: doc.documentID,
                    userId: data["userID"] as? String ?? "",
                    username: data["username"] as? String ?? "Unknown",
                    text: data["text"] as? String ?? "",
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                )
            } ?? []
            
        }
    }
    
    func addComment() {
        guard !newComment.isEmpty else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // 1. Fetch the current user's username from Firestore
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error)")
                return
            }
            // Fallback to "Unknown" if we don't get a username
            let username = snapshot?.data()?["username"] as? String ?? "Unknown"
            
            // 2. Build the comment data
            let commentData: [String: Any] = [
                "userID": uid,
                "username": username,
                "text": self.newComment,
                "timestamp": Timestamp(date: Date())
            ]
            
            // 3. Write the comment to Firestore
            Firestore.firestore()
                .collection("posts")
                .document(self.post.id)
                .collection("comments")
                .addDocument(data: commentData) { err in
                    if let err = err {
                        print("Error adding comment: \(err)")
                    } else {
                        self.newComment = ""
                    }
                }
        }
    }
    
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 10) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(comments) { comment in
                            HStack(alignment: .top, spacing: 8) {
                                // Profile picture
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                
                                // Username & comment
                                VStack(alignment: .leading, spacing: 4) {
                                    // Username + comment on same line
                                    Text(comment.username)
                                        .fontWeight(.semibold) +
                                    Text(" \(comment.text)")
                                    
                                    // Timestamp below in smaller font
                                    Text(comment.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal)
                }
                
                // Comment input at the bottom
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addComment) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Comments", displayMode: .inline)
        }
            .onAppear { fetchComments() }
        }
    }


struct Comment: Identifiable {
    var id: String
    var userId: String
    var username: String
    var text: String
    var timestamp: Date
}



#Preview {
    CommentsView(post: Post.MOCK_POSTS[0])
}
