//
//  CommentsView.swift
//  Runr
//
//  Created by Noah Moran on 6/2/2025.
//

import SwiftUI
import Firebase

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
                    text: data["text"] as? String ?? "",
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                )
            } ?? []
        }
    }

    func addComment() {
        guard !newComment.isEmpty else { return }

        let commentRef = Firestore.firestore()
            .collection("posts")
            .document(post.id)
            .collection("comments")
            .document()

        let commentData: [String: Any] = [
            "userID": "currentUser123",
            "text": newComment,
            "timestamp": Timestamp(date: Date())
        ]

        commentRef.setData(commentData) { error in
            if let error = error {
                print("Error adding comment: \(error.localizedDescription)")
            } else {
                self.newComment = ""
            }
        }
    }

    var body: some View {
        VStack {
            List(comments) { comment in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(comment.text)
                            .font(.body)
                        Text(comment.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
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
        .onAppear {
            fetchComments()
        }
    }
}


struct Comment: Identifiable {
    var id: String
    var userId: String
    var text: String
    var timestamp: Date
}


#Preview {
    CommentsView(post: Post.MOCK_POSTS[0])
}
