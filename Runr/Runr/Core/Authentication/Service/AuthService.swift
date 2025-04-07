//
//  AuthViewModel.swift
//  Runr
//
//  Created by Noah Moran on 13/1/2025.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestoreCombineSwift
import FirebaseStorage

class AuthService: ObservableObject {
    
    // Variables, States, etc.
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    static let shared = AuthService()
    
    private let storageRef = Storage.storage().reference()
    
    init() {
        self.userSession = Auth.auth().currentUser
        if let _ = self.userSession {
            Task {
                do {
                    try await loadUserData()
                } catch {
                    print("DEBUG: Failed to load user data in init: \(error.localizedDescription)")
                }
            }
        }
    }

    
    // This is a function to be able to follow a user
    func followUser(userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let targetUserRef = Firestore.firestore().collection("users").document(userId)
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        
        // Update the followed user's document: increment followerCount and add currentUserId to followers array.
        try await targetUserRef.updateData([
            "followerCount": FieldValue.increment(Int64(1)),
            "followers": FieldValue.arrayUnion([currentUserId])
        ])
        
        // Optionally, update the current user's following list.
        try await currentUserRef.updateData([
            "following": FieldValue.arrayUnion([userId])
        ])
    }
    
    func unfollowUser(userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let targetUserRef = Firestore.firestore().collection("users").document(userId)
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        
        // Decrement follower count on the target user
        try await targetUserRef.updateData([
            "followerCount": FieldValue.increment(Int64(-1)),
            "followers": FieldValue.arrayRemove([currentUserId])
        ])
        
        // Remove from the current user's "following" array
        try await currentUserRef.updateData([
            "following": FieldValue.arrayRemove([userId])
        ])
    }

    func isCurrentUserFollowingUser(_ userId: String) async throws -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        let snapshot = try await currentUserRef.getDocument()
        if let data = snapshot.data(), let followingArray = data["following"] as? [String] {
            return followingArray.contains(userId)
        }
        return false
    }

    
    // Uploads a profile image to Firebase Storage and updates Firestore with the image URL
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw URLError(.badURL)
        }
        guard let imageData = image.jpegData(compressionQuality: 0.4) else {
            throw URLError(.badURL)
        }

        let profileImageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        print("DEBUG: Starting image upload for user \(userId)...")

        // Upload the image and check for completion
        do {
            let metadataResult = try await profileImageRef.putDataAsync(imageData, metadata: metadata)
            print("DEBUG: Image successfully uploaded with metadata: \(metadataResult)")
        } catch {
            print("DEBUG: Error uploading image to Firebase Storage: \(error.localizedDescription)")
            throw error
        }

        // Retrieve download URL AFTER successful upload
        do {
            let downloadURL = try await profileImageRef.downloadURL()
            print("DEBUG: Retrieved download URL: \(downloadURL.absoluteString)")

            // Update Firestore with new profile image URL
            let userRef = Firestore.firestore().collection("users").document(userId)
            try await userRef.updateData(["profileImageUrl": downloadURL.absoluteString])

            DispatchQueue.main.async {
                self.currentUser?.profileImageUrl = downloadURL.absoluteString
            }

            return downloadURL.absoluteString
        } catch {
            print("DEBUG: Failed to retrieve download URL: \(error.localizedDescription)")
            throw error
        }
    }


    
    
    @MainActor
    func login(withEmail email: String, password: String) async throws {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                self.userSession = result.user
                try await loadUserData() // Load user data after login
            } catch {
                print("DEBUG: Failed to log in with error \(error.localizedDescription)")
            }
        }
    
    @MainActor
    func createUser(email: String, password: String, username: String, realName: String) async throws -> AuthDataResult {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            print("DEBUG: Did create user..")
            
            await uploadUserData(uid: result.user.uid, username: username, email: email, realName: realName)
            print("DEBUG: Did upload user data...")
            
            try await loadUserData() // Load user data after creation
            
            return result // Return the result so it can be used in RegistrationViewModel.swift
        } catch {
            print("DEBUG: Failed to register user with error \(error.localizedDescription)")
            throw error
        }
    }

    
    // Function to fetch the current user's previous runs
    func fetchUserRuns() async throws -> [RunData] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        
        let snapshot = try await Firestore.firestore().collection("users").document(uid).collection("runs").getDocuments()
        
        let runs = snapshot.documents.compactMap { doc -> RunData? in
            do {
                let data = try doc.data(as: RunData.self)
                return data
            } catch {
                print("DEBUG: Failed to decode run data with error \(error.localizedDescription)")
                return nil
            }
        }
        
        return runs
    }
    
    // Function to fetch ANY USER's runs
    func fetchUserRuns(for userId: String) async throws -> [RunData] {
        let snapshot = try await Firestore.firestore().collection("users").document(userId).collection("runs").getDocuments()
        let runs = snapshot.documents.compactMap { doc -> RunData? in
            do {
                let data = try doc.data(as: RunData.self)
                return data
            } catch {
                print("DEBUG: Failed to decode run data with error \(error.localizedDescription)")
                return nil
            }
        }
        return runs
    }


    
    
    // This function loads user data from the Google Firebase database
    // Specifically, it loads the CURRENT USER's data, it only works for the current user
    func loadUserData() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        
        if let data = snapshot.data() {
            let user = try Firestore.Decoder().decode(User.self, from: data)
            DispatchQueue.main.async {
                self.userSession = Auth.auth().currentUser
                self.currentUser = user
            }
            print("DEBUG: Loaded user data: \(user)")
        }
    }

    // This function is used to sign out of a user profile
    func signout(){
        try? Auth.auth().signOut()
        self.userSession = nil
    }
    
    private func uploadUserData(uid: String, username: String, email: String, realName: String) async {
        // Initialize with an empty tags array
        let user = User(id: uid, username: username, email: email, realName: realName, tags: [])
        guard let encodedUser = try? Firestore.Encoder().encode(user) else { return }
        try? await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
    }

}


extension AuthService {
    /// Fetch a user document from Firestore by its UID.
    func fetchUser(for uid: String) async throws -> User {
        let doc = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument()
        
        // Check if the document actually exists
        guard doc.exists else {
            throw URLError(.badServerResponse)
        }
        
        let user = try doc.data(as: User.self)
        
        return user
    }

}

extension AuthService {
    /// Fetches a download URL for an image stored in Firebase Storage.
    /// - Parameters:
    ///   - filename: The name of the file (e.g., "someImage.jpg").
    ///   - folder: The folder/path in Storage (default: "runningProgramImages").
    /// - Returns: A string containing the download URL.
    func fetchDownloadURL(for filename: String, in folder: String = "runningProgramImages") async throws -> String {
        let storagePath = "\(folder)/\(filename)"
        let reference = Storage.storage().reference().child(storagePath)
        
        do {
            let url = try await reference.downloadURL()
            return url.absoluteString
        } catch {
            print("DEBUG: Error fetching download URL for \(storagePath): \(error.localizedDescription)")
            throw error
        }
    }
}
