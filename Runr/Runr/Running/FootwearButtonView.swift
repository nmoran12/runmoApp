//
//  FootwearButtonView.swift
//  Runr
//
//  Created by Noah Moran on 9/1/2025.
//

import SwiftUI
import FirebaseFirestore

struct FootwearButtonView: View {
    @Binding var selectedFootwear: String
    @State private var showFootwearMenu = false // Controls visibility of the pop-down menu
    @State private var footwearOptions: [String] = ["Adidas", "Nike Superfly"] // Initial list of options
    @State private var searchQuery = "" // Stores the search query

    var body: some View {
        VStack {
            // The main button to toggle the footwear menu
            HStack(spacing: -3) {
                Button(action: {
                    withAnimation {
                        showFootwearMenu.toggle()
                    }
                }) {
                    HStack {
                        Text(selectedFootwear)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(10)
                        
                        Image(systemName: "shoe")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                            .padding(10)
                    }
                }
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(.black)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            
            if showFootwearMenu {
                // The pop-down menu
                VStack(spacing: 12) {
                    // Search bar
                    TextField("Search or add new footwear...", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, 8)
                    
                    // Footwear list (no extra ScrollView)
                    List {
                        ForEach(filteredFootwearOptions(), id: \.self) { option in
                            HStack {
                                Text(option)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFootwear = option
                                showFootwearMenu = false
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteFootwear(option)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)  // If you want to limit the height
                    .listStyle(.plain)
                    
                    // If user typed something not in the list, show "Add new footwear" button
                    if !searchQuery.isEmpty && !footwearOptions.contains(searchQuery) {
                        Button(action: {
                            footwearOptions.append(searchQuery)
                            selectedFootwear = searchQuery
                            searchQuery = ""
                            showFootwearMenu = false
                            addFootwearToFirestore(name: selectedFootwear)
                        }) {
                            HStack {
                                Text("Add '\(searchQuery)' to Footwear")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "plus")
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                    
                    // NavigationLink to FootwearStats view
                    NavigationLink(destination: FootwearStats()) {
                        HStack {
                            Text("View Footwear Stats")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 12)
                .background(Color(.systemGroupedBackground))
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                .padding(.top, 5)
                .transition(.move(edge: .top))
                .onAppear {
                    loadFootwearFromFirestore()
                }
                
            }
        }
    }
            
            // Filter options based on search query
            private func filteredFootwearOptions() -> [String] {
                if searchQuery.isEmpty {
                    return footwearOptions
                } else {
                    return footwearOptions.filter { $0.lowercased().contains(searchQuery.lowercased()) }
                }
            }
    
    // This is used to delete footwear both locally and from Google Firebase
    private func deleteFootwear(_ option: String) {
        // 1) Remove from the local array so the UI updates immediately
        if let index = footwearOptions.firstIndex(of: option) {
            footwearOptions.remove(at: index)
        }

        // 2) Remove from Firestore’s "footwearStats" map
        guard let userId = AuthService.shared.userSession?.uid else {
            print("User not logged in.")
            return
        }

        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userId)

        // Remove the key from the footwearStats dictionary
        docRef.updateData([
            "footwearStats.\(option)": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("Error removing footwear from Firestore: \(error)")
            } else {
                print("Successfully removed footwear from Firestore.")
            }
        }
    }
    
    // MARK: - Load from Firestore
        private func loadFootwearFromFirestore() {
            guard let userId = AuthService.shared.userSession?.uid else {
                print("User not logged in.")
                return
            }
            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching footwearStats: \(error)")
                    return
                }
                guard let data = snapshot?.data(),
                      let footwearStats = data["footwearStats"] as? [String: Double] else {
                    print("No footwearStats found.")
                    return
                }
                // The keys of footwearStats are your footwear names
                self.footwearOptions = Array(footwearStats.keys)
                print("Loaded footwear from Firestore: \(self.footwearOptions)")
            }
        }
    
    // MARK: - Add new footwear to Firestore
        private func addFootwearToFirestore(name: String) {
            guard let userId = AuthService.shared.userSession?.uid else {
                print("User not logged in.")
                return
            }
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(userId)

            // By default, set mileage to 0.0 for a new shoe
            docRef.updateData([
                "footwearStats.\(name)": 0.0
            ]) { error in
                if let error = error {
                    print("Error adding footwear to Firestore: \(error)")
                } else {
                    print("Successfully added footwear to Firestore.")
                }
            }
        }

        }

#Preview {
    @State var previewFootwear = "Select Footwear"
    FootwearButtonView(selectedFootwear: $previewFootwear)
}

