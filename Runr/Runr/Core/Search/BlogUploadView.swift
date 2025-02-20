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
        let collectionRef = db.collection("exploreFeedItems")

        // Fetch the highest numeric ID
        collectionRef.order(by: FieldPath.documentID(), descending: true).limit(to: 1).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching last document ID: \(error.localizedDescription)")
                return
            }

            var newId = 1
            if let lastDoc = snapshot?.documents.first, let lastDocId = Int(lastDoc.documentID) {
                newId = lastDocId + 1
            }

            let blogData: [String: Any] = [
                "title": title,
                "content": content,
                "category": "Blog",
                "imageUrl": "https://via.placeholder.com/200",
                "timestamp": Timestamp()
            ]

            collectionRef.document("\(newId)").setData(blogData) { error in
                if let error = error {
                    print("Error uploading blog: \(error.localizedDescription)")
                } else {
                    print("Blog uploaded successfully with ID: \(newId)")
                    title = ""
                    content = ""
                    
                    // ✅ Dismiss the upload view and go back to the Explore page
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

#Preview {
    BlogUploadView()
}

