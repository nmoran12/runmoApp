//
//  UploadPostViewModel.swift
//  InstagramTutorial
//
//  Created by Noah Moran on 3/1/2025.
//

import Firebase
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import SwiftUI


@MainActor
class UploadPostViewModel: ObservableObject {
    @Published var imageData: Data?

    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage) } }
    }
    
    @Published var postImage: Image?
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        
        self.postImage = Image(uiImage: uiImage)
        self.imageData = data // Store the image data for uploading
    }

    
    func uploadPost(caption: String, runData: RunData?) async {
        guard let userId = AuthService.shared.userSession?.uid else { return }
        guard let imageData = imageData else { return } // Use the stored image data
        
        // Upload image to Firebase Storage
        let storageRef = Storage.storage().reference().child("post_images/\(UUID().uuidString).jpg")
        do {
            let _ = try await storageRef.putData(imageData, metadata: nil)
            let imageUrl = try await storageRef.downloadURL().absoluteString
            
            // Prepare post data
            let postId = UUID().uuidString
            let postData: [String: Any] = [
                "id": postId,
                "ownerUid": userId,
                "caption": caption,
                "likes": 0,
                "imageUrl": imageUrl,
                "timestamp": Timestamp(date: Date()),
                "runData": runData != nil ? [
                    "distance": runData!.distance,
                    "time": runData!.elapsedTime
                ] : NSNull()
            ]
            
            // Save post to Firestore
            try await Firestore.firestore().collection("posts").document(postId).setData(postData)
            print("DEBUG: Post uploaded successfully")
        } catch {
            print("DEBUG: Failed to upload post with error \(error.localizedDescription)")
        }
    }

}
