//
//  BlogUploadView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI
import Firebase
import FirebaseStorage

struct BlogUploadView: View {
    @State private var title = ""
    @State private var content = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isUploadingImage = false
    @Environment(\.presentationMode) var presentationMode

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
            
            Button("Select Image") {
                showImagePicker.toggle()
            }
            .padding(.bottom)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(10)
                    .padding(.bottom)
            }

            Spacer()

            Button(action: uploadBlog) {
                if isUploadingImage {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Upload Blog")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    // MARK: - Upload Flow

    func uploadBlog() {
        guard !title.isEmpty, !content.isEmpty else {
            print("Title or content is empty.")
            return
        }
        
        let db = Firestore.firestore()
        let counterRef = db.collection("counters").document("blogCounter")
        
        // If a user-selected image exists, upload it
        if let selectedImage = selectedImage,
           let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
            
            isUploadingImage = true
            let storageRef = Storage.storage().reference().child("blogImages/\(UUID().uuidString).jpg")
            
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                self.isUploadingImage = false
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        return
                    }
                    guard let finalUrl = url?.absoluteString else {
                        print("No valid download URL.")
                        return
                    }
                    // Proceed with the Firestore transaction using the uploaded image URL
                    self.checkAndRunUpload(db: db, counterRef: counterRef, finalImageUrl: finalUrl)
                }
            }
        } else {
            // If no image is selected, use a placeholder image URL
            self.checkAndRunUpload(db: db, counterRef: counterRef, finalImageUrl: "https://via.placeholder.com/200")
        }
    }
    
    func checkAndRunUpload(db: Firestore, counterRef: DocumentReference, finalImageUrl: String) {
        // Check if the blog counter exists; if not, initialize it
        counterRef.getDocument { document, error in
            if let error = error {
                print("Error checking blog counter: \(error.localizedDescription)")
                return
            }
            if document == nil || !document!.exists {
                counterRef.setData(["lastBlogId": 0]) { error in
                    if let error = error {
                        print("Error initializing blog counter: \(error.localizedDescription)")
                        return
                    }
                    print("Initialized blog counter. Now proceeding with blog upload.")
                    self.runUploadTransaction(db: db, counterRef: counterRef, finalImageUrl: finalImageUrl)
                }
            } else {
                self.runUploadTransaction(db: db, counterRef: counterRef, finalImageUrl: finalImageUrl)
            }
        }
    }
    
    func runUploadTransaction(db: Firestore, counterRef: DocumentReference, finalImageUrl: String) {
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
            
            // Generate new blog data with the uploaded image URL
            let blogData: [String: Any] = [
                "title": title,
                "content": content,
                "category": "Blog",
                "imageUrl": finalImageUrl,
                "timestamp": Timestamp(),
                "authorId": currentUserId,
                "authorUsername": currentUsername
            ]
            
            // Set the blog document with a custom ID format
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
                // Optionally clear the selected image if needed:
                selectedImage = nil
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    BlogUploadView()
}


