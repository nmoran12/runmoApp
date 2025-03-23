//
//  BlogUploadView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI
import Firebase

struct BlogUploadView: View {
    @State private var title = ""
    @State private var content = ""
    @Environment(\.presentationMode) var presentationMode // Add this to dismiss the view

    var body: some View {
        VStack(alignment: .leading) {
            Text("Create a Blog")
                .font(.headline)
                .padding(.bottom, 5)

            TextField("Enter blog title...", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)

            TextEditor(text: $content)
                .frame(height: 200)
                .border(Color.gray.opacity(0.5), width: 1)
                .cornerRadius(8)
                .padding(.bottom)

            Spacer()

            Button(action: uploadBlog) {
                Text("Upload Blog")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    func uploadBlog() {
        guard !title.isEmpty, !content.isEmpty else {
            print("Title or content is empty.")
            return
        }

        let db = Firestore.firestore()
        let counterRef = db.collection("counters").document("blogCounter")

        // ✅ Step 1: Check if the counter exists
        counterRef.getDocument { document, error in
            if let error = error {
                print("Error checking blog counter: \(error.localizedDescription)")
                return
            }

            if document == nil || !document!.exists {
                // ✅ Step 2: Initialize counter if it doesn't exist
                counterRef.setData(["lastBlogId": 0]) { error in
                    if let error = error {
                        print("Error initializing blog counter: \(error.localizedDescription)")
                        return
                    }
                    print("Initialized blog counter. Now proceeding with blog upload.")
                    self.runUploadTransaction(db: db, counterRef: counterRef)
                }
            } else {
                // ✅ Step 3: If counter exists, proceed with the transaction
                self.runUploadTransaction(db: db, counterRef: counterRef)
            }
        }
    }

    func runUploadTransaction(db: Firestore, counterRef: DocumentReference) {
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let counterDocument: DocumentSnapshot
            do {
                counterDocument = try transaction.getDocument(counterRef)
            } catch {
                print("Error fetching blog counter: \(error.localizedDescription)")
                return nil
            }

            var newId = 1
            if let lastId = counterDocument.data()?["lastBlogId"] as? Int {
                newId = lastId + 1
            }

            // Update the counter document with the new ID
            transaction.updateData(["lastBlogId": newId], forDocument: counterRef)
            
            // Grab current user ID and username from your auth/user service
                    guard let currentUserId = AuthService.shared.userSession?.uid else {
                        print("No current user ID found.")
                        return nil
                    }
                    let currentUsername = AuthService.shared.currentUser?.username ?? "Unknown User"

            // Generate new blog data
                    let blogData: [String: Any] = [
                        "title": title,
                        "content": content,
                        "category": "Blog",
                        "imageUrl": "https://via.placeholder.com/200",
                        "timestamp": Timestamp(),
                        "authorId": currentUserId,
                        "authorUsername": currentUsername
                    ]

            // Set the blog document with the custom ID format
            let blogRef = db.collection("exploreFeedItems")
                .document("blogs")
                .collection("individualBlogs")
                .document("blogPost\(newId)")
            
            transaction.setData(blogData, forDocument: blogRef)

            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error.localizedDescription)")
            } else {
                print("Blog uploaded successfully!")
                title = ""
                content = ""

                // ✅ Dismiss the upload view
                presentationMode.wrappedValue.dismiss()
            }
        }
    }


}

#Preview {
    BlogUploadView()
}

