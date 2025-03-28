//
//  SavedItemsView.swift
//  Runr
//
//  Created by Noah Moran on 28/3/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct SavedItemsView: View {
    @State private var savedItems: [ExploreFeedItem] = []
    
    var runningPrograms: [ExploreFeedItem] {
        savedItems.filter { $0.category == "runningProgram" }
    }
    var blogItems: [ExploreFeedItem] {
        savedItems.filter { $0.category == "Blog" }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Running Programs section
                    if !runningPrograms.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Running Programs")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(runningPrograms, id: \.exploreFeedId) { item in
                                        NavigationLink(destination: RunningProgramContentView(program: RunningProgram(from: item))) {
                                            RunningProgramCard(program: convertToRunningProgram123(from: item))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Blogs section
                    if !blogItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Blogs")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(blogItems, id: \.exploreFeedId) { item in
                                        NavigationLink(destination: BlogContentView(blog: item)) {
                                            BlogCard(blog: convertToBlog123(from: item))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    if runningPrograms.isEmpty && blogItems.isEmpty {
                        Text("No saved items yet.")
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            // Match the "Explore" style
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Saved Items")
                        .fontWeight(.semibold)
                        .font(.system(size: 20))
                }
            }
            .onAppear {
                Task { await fetchSavedItems() }
            }
        }
    }
    
    func fetchSavedItems() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("savedItems")
                .getDocuments()
            
            var tempItems: [ExploreFeedItem] = []
            for doc in snapshot.documents {
                if let item = try? doc.data(as: ExploreFeedItem.self) {
                    tempItems.append(item)
                }
            }
            
            DispatchQueue.main.async {
                self.savedItems = tempItems
            }
        } catch {
            print("Error fetching saved items: \(error.localizedDescription)")
        }
    }
}


#Preview {
    SavedItemsView()
}
