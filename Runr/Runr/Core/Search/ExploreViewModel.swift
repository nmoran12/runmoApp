//
//  ExploreViewModel.swift
//  Runr
//
//  Created by Noah Moran on 6/2/2025.
//

import SwiftUI
import Firebase

@MainActor
class ExploreViewModel: ObservableObject {
    
    @Published var users: [User] = []
    @Published var searchText = ""

    init() {
        Task {
            await fetchUsers()
        }
    }

    // Fetch users from Firestore's "users" collection
    func fetchUsers() async {
        do {
            let snapshot = try await Firestore.firestore().collection("users").getDocuments()
            
            DispatchQueue.main.async {
                self.users = snapshot.documents.compactMap { doc -> User? in
                    let data = doc.data()
                    print("Fetched user data: \(data)") // Debugging log
                    
                    guard let id = data["id"] as? String,
                          let username = data["username"] as? String,
                          let email = data["email"] as? String else {
                        return nil
                    }
                    
                    let realName = data["realName"] as? String // Handle missing fullname
                    let profileImageUrl = data["profileImageUrl"] as? String
                    
                    return User(id: id, username: username, profileImageUrl: profileImageUrl, email: email, realName: realName)
                }
                
                print("Loaded \(self.users.count) users from Firestore")
            }
        } catch {
            print("Error fetching users: \(error.localizedDescription)")
        }
    }
    
    // Search functionality filtering based on username and fullname
    var filteredUsers: [User] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedSearch.isEmpty {
            return users
        } else {
            return users.filter {
                $0.username.trimmingCharacters(in: .whitespacesAndNewlines)
                    .localizedCaseInsensitiveContains(trimmedSearch) ||
                ($0.fullname?.trimmingCharacters(in: .whitespacesAndNewlines)
                    .localizedCaseInsensitiveContains(trimmedSearch) ?? false)
            }
        }
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        RunrSearchView()
    }
}
