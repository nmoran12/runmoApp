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
import FirebaseFirestore
import FirebaseStorage

/// Centralized service for authentication, profile, social, and run data operations.
final class AuthService: ObservableObject {
    // MARK: - Published Properties
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?

    // MARK: - Shared Instance
    static let shared = AuthService()

    // MARK: - Private Properties
    private let storageRef = Storage.storage().reference()

    // MARK: - Initialization
    private init() {
        self.userSession = Auth.auth().currentUser
        if userSession != nil {
            Task { try? await self.loadUserData() }
        }
    }
}

// MARK: - Authentication (Login / Signup / Sign Out)
extension AuthService {
    /// Signs in a user with email and password.
    @MainActor
    func login(withEmail email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.userSession = result.user
        try await loadUserData()
    }

    /// Creates a new user account and uploads initial profile data.
    @MainActor
    func createUser(email: String, password: String, username: String, realName: String) async throws -> AuthDataResult {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        self.userSession = result.user
        await uploadUserData(uid: result.user.uid, username: username, email: email, realName: realName)
        try await loadUserData()
        return result
    }

    /// Signs out the current user.
    func signout() {
        try? Auth.auth().signOut()
        self.userSession = nil
    }
}

// MARK: - Profile Data (Load / Upload)
extension AuthService {
    /// Loads the current user's profile data from Firestore.
    func loadUserData() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let snapshot = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument()
        guard let data = snapshot.data() else { return }
        let user = try Firestore.Decoder().decode(User.self, from: data)
        DispatchQueue.main.async {
            self.userSession = Auth.auth().currentUser
            self.currentUser = user
        }
    }

    /// Uploads a profile image to Storage and updates Firestore with its URL.
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else { throw URLError(.badURL) }
        guard let imageData = image.jpegData(compressionQuality: 0.4) else { throw URLError(.badURL) }
        let ref = storageRef.child("profile_images/\(uid).jpg")
        _ = try await ref.putDataAsync(imageData, metadata: StorageMetadata())
        let url = try await ref.downloadURL()
        try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .updateData(["profileImageUrl": url.absoluteString])
        DispatchQueue.main.async { self.currentUser?.profileImageUrl = url.absoluteString }
        return url.absoluteString
    }

    /// Saves initial user data (username, email, realName) in Firestore after registration.
    private func uploadUserData(uid: String, username: String, email: String, realName: String) async {
        let newUser = User(id: uid, username: username, email: email, realName: realName, tags: [])
        guard let data = try? Firestore.Encoder().encode(newUser) else { return }
        try? await Firestore.firestore().collection("users").document(uid).setData(data)
    }
}

// MARK: - Social (Follow / Unfollow / Check Following)
extension AuthService {
    /// Follows a user: increments their followerCount and updates current user's following list.
    func followUser(userId: String) async throws {
        guard let myId = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(userId)
        let meRef   = Firestore.firestore().collection("users").document(myId)
        try await userRef.updateData([
            "followerCount": FieldValue.increment(Int64(1)),
            "followers": FieldValue.arrayUnion([myId])
        ])
        try await meRef.updateData(["following": FieldValue.arrayUnion([userId])])
    }

    /// Unfollows a user: decrements their followerCount and updates current user's following list.
    func unfollowUser(userId: String) async throws {
        guard let myId = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(userId)
        let meRef   = Firestore.firestore().collection("users").document(myId)
        try await userRef.updateData([
            "followerCount": FieldValue.increment(Int64(-1)),
            "followers": FieldValue.arrayRemove([myId])
        ])
        try await meRef.updateData(["following": FieldValue.arrayRemove([userId])])
    }

    /// Returns whether the current user is following the given user.
    func isCurrentUserFollowingUser(_ userId: String) async throws -> Bool {
        guard let myId = Auth.auth().currentUser?.uid else { return false }
        let snapshot = try await Firestore.firestore().collection("users").document(myId).getDocument()
        let following = snapshot.data()?[
            "following"
        ] as? [String] ?? []
        return following.contains(userId)
    }

    /// Fetches the list of user IDs that the current user is following.
    func fetchFollowingList() async throws -> [String] {
        guard let myId = Auth.auth().currentUser?.uid else { return [] }
        let snapshot = try await Firestore.firestore().collection("users").document(myId).getDocument()
        return snapshot.data()?[
            "following"
        ] as? [String] ?? []
    }
}

// MARK: - Run Data (Fetch All / Fetch Paginated)
extension AuthService {
    /// Fetches all runs for the current user.
    func fetchUserRuns() async throws -> [RunData] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        return try await fetchRuns(from: uid)
    }

    /// Fetches all runs for any specified user.
    func fetchUserRuns(for userId: String) async throws -> [RunData] {
        return try await fetchRuns(from: userId)
    }

    /// Shared helper to fetch runs collection for a user.
    private func fetchRuns(from userId: String) async throws -> [RunData] {
        let snap = try await Firestore.firestore().collection("users").document(userId).collection("runs").getDocuments()
        return snap.documents.compactMap { try? $0.data(as: RunData.self) }
    }

    /// Fetches runs in paginated batches for either current or specified user.
    func fetchUserRunsPaginated(
        for userId: String? = nil,
        lastDocument: DocumentSnapshot? = nil,
        limit: Int = 7
    ) async throws -> ([RunData], DocumentSnapshot?) {
        let uid = userId ?? Auth.auth().currentUser?.uid
        guard let validId = uid else { return ([], nil) }
        var query = Firestore.firestore()
            .collection("users")
            .document(validId)
            .collection("runs")
            .order(by: "date", descending: true)
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snap = try await query.getDocuments()
        let results = snap.documents.compactMap { try? $0.data(as: RunData.self) }
        return (results, snap.documents.last)
    }
}

// MARK: - Utilities (User Fetch / Storage URL)
extension AuthService {
    /// Retrieves a single User by UID.
    func fetchUser(for uid: String) async throws -> User {
        let doc = try await Firestore.firestore().collection("users").document(uid).getDocument()
        guard doc.exists, let user = try? doc.data(as: User.self) else {
            throw URLError(.badServerResponse)
        }
        return user
    }

    /// Retrieves a download URL for a file in Firebase Storage.
    func fetchDownloadURL(for filename: String, in folder: String = "runningProgramImages") async throws -> String {
        return try await storageRef.child("\(folder)/\(filename)").downloadURL().absoluteString
    }
}
