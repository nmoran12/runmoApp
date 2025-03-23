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
    @Published var exploreFeedItems: [ExploreFeedItem] = []
    @Published var users: [User] = [] // 🔹 Add users array
    @Published var searchText = ""

    init() {
        Task {
            await fetchRunningPrograms()
            await fetchUsers()
            await fetchBlogs()
        }
    }

    // Fetch running programs to display in its explore tab
    func fetchRunningPrograms() async {
        do {
            let db = Firestore.firestore()
            
            // If you know the parent doc is "runningPrograms":
            let subSnapshot = try await db
                .collection("exploreFeedItems")
                .document("runningPrograms")
                .collection("programs")
                .getDocuments()
            
            var programItems: [ExploreFeedItem] = []
            for doc in subSnapshot.documents {
                if let parsed = parseDocument(doc) {
                    programItems.append(parsed)
                }
            }
            
            DispatchQueue.main.async {
                self.exploreFeedItems = programItems
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
    
    // Fetch blog programs to display in its explore tab
    // In ExploreViewModel.swift, add this new method:
    func fetchBlogs() async {
        do {
            let db = Firestore.firestore()
            let blogSnapshot = try await db
                .collection("exploreFeedItems")
                .document("blogs")
                .collection("individualBlogs")
                .getDocuments()
            
            var blogItems: [ExploreFeedItem] = []
            for doc in blogSnapshot.documents {
                if let parsed = parseDocument(doc) {
                    blogItems.append(parsed)
                }
            }
            
            DispatchQueue.main.async {
                // Merge blogs with your existing items
                self.exploreFeedItems.append(contentsOf: blogItems)
            }
            
        } catch {
            print("Error fetching blogs: \(error)")
        }
    }



    private func parseDocument(_ doc: QueryDocumentSnapshot) -> ExploreFeedItem? {
        let data = doc.data()
        
        guard let title = data["title"] as? String,
              let category = data["category"] as? String,
              let imageUrl = data["imageUrl"] as? String
        else { return nil }
        
        let content = data["content"] as? String
            ?? data["planOverview"] as? String
            ?? ""
        
        // Optional author fields
        let authorId = data["authorId"] as? String
        let authorUsername = data["authorUsername"] as? String

        return ExploreFeedItem(
            exploreFeedId: doc.documentID,
            title: title,
            content: content,
            category: category,
            imageUrl: imageUrl,
            authorId: authorId,
            authorUsername: authorUsername
        )
    }




    // Fetch users from Firestore for the search function
    func fetchUsers() async {
        do {
            let snapshot = try await Firestore.firestore().collection("users").getDocuments()
            DispatchQueue.main.async {
                self.users = snapshot.documents.compactMap { doc -> User? in
                    let data = doc.data()
                    guard let username = data["username"] as? String,
                          let email = data["email"] as? String, // 🔹 Ensure `email` is included
                          let profileImageUrl = data["profileImageUrl"] as? String? else { return nil }

                    return User(
                        id: doc.documentID,
                        username: username,
                        profileImageUrl: profileImageUrl,
                        fullname: data["fullname"] as? String,
                        bio: data["bio"] as? String,
                        email: email, // 🔹 Required field
                        realName: data["realName"] as? String,
                        totalDistance: data["totalDistance"] as? Double ?? 0.0,
                        totalTime: data["totalTime"] as? Double ?? 0.0,
                        averagePace: data["averagePace"] as? Double ?? 0.0
                    )
                }
            }
        } catch {
            print("Error fetching users: \(error.localizedDescription)")
        }
    }


    // Filter users based on search input
    var filteredUsers: [User] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ensure search text is not empty
        if trimmedSearch.isEmpty { return [] }
        
        // Get current user ID
        guard let currentUserId = AuthService.shared.userSession?.uid else { return [] }
        
        // Filter users based on search and exclude the current user
        return users
            .filter { $0.username.localizedCaseInsensitiveContains(trimmedSearch) && $0.id != currentUserId }
            .prefix(5) // Limit to 5 users
            .map { $0 } // Convert ArraySlice<User> back to [User]
    }


}

