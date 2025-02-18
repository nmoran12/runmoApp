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

class AuthService: ObservableObject {
    
    // Variables, States, etc.
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    static let shared = AuthService()
    
    init(){
        self.userSession = Auth.auth().currentUser
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
        let user = User(id: uid, username: username, email: email, realName: realName)
        guard let encodedUser = try? Firestore.Encoder().encode(user) else { return }
        
        try? await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
    }
}
