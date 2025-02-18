//
//  LoginViewModel.swift
//  Runr
//
//  Created by Noah Moran on 13/1/2025.
//

import Foundation
import Firebase

class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    func signIn() async throws {
        try await AuthService.shared.login(withEmail: email, password: password)
    }
    
    func signout() {
        AuthService.shared.signout()
        print("User signed out")
    }
}
