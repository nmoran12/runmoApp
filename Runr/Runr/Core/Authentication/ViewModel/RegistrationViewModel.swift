//
//  RegistrationViewModel.swift
//  Runr
//
//  Created by Noah Moran on 13/1/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class RegistrationViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var realName = ""

    func createUser() async throws {
        let authResult = try await AuthService.shared.createUser(email: email, password: password, username: username, realName: realName)
        
        // Directly assign userId without optional binding
        let userId = authResult.user.uid
        
        try await storeUserProfile(userId: userId, username: username, email: email, realName: realName)
    }

    func storeUserProfile(userId: String, username: String, email: String, realName: String) async throws {
        let db = Firestore.firestore()

        let userData: [String: Any] = [
            "id": userId,
            "username": username,
            "email": email,
            "realName": realName,
            "totalDistance": 0,
            "totalTime": 0
        ]

        do {
            try await db.collection("users").document(username).setData(userData)
            print("DEBUG: Successfully stored user profile for \(username)")
        } catch {
            print("DEBUG: Failed to store user profile \(error.localizedDescription)")
            throw error
        }
    }
}

