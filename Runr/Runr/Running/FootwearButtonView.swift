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
        Button(action: {
            withAnimation {
                showFootwearMenu.toggle()
            }
        }) {
            Image(systemName: "shoe.fill") // Using the filled shoe icon
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary) // primary icon
                .frame(width: 40, height: 40)
                .background(Color(UIColor.systemBackground))
                .clipShape(Circle())
                .shadow(color: Color.primary.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .overlay(
            Group {
                if showFootwearMenu {
                    VStack(spacing: 12) {
                        // Search bar
                        TextField("Search or add new footwear...", text: $searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.top, 8)
                        
                        // Footwear list (without an extra ScrollView)
                        List {
                            ForEach(filteredFootwearOptions(), id: \.self) { option in
                                HStack {
                                    Text(option)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
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
                        .frame(maxHeight: 200)
                        .listStyle(.plain)
                        
                        // "Add new footwear" button if search query doesn't match.
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
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(8)
                                .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
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
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 12)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.primary.opacity(0.2), radius: 5, x: 0, y: 2)
                    .offset(y: 50) // Positions the menu 50 points below the button
                    .transition(.move(edge: .top))
                    .onAppear {
                        loadFootwearFromFirestore()
                    }
                }
            },
            alignment: .top
        )
    }
    
    // Filter options based on search query.
    private func filteredFootwearOptions() -> [String] {
        if searchQuery.isEmpty {
            return footwearOptions
        } else {
            return footwearOptions.filter { $0.lowercased().contains(searchQuery.lowercased()) }
        }
    }
    
    // Delete footwear both locally and from Firestore.
    private func deleteFootwear(_ option: String) {
        if let index = footwearOptions.firstIndex(of: option) {
            footwearOptions.remove(at: index)
        }
        guard let userId = AuthService.shared.userSession?.uid else {
            print("User not logged in.")
            return
        }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userId)
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
    
    // Load footwear options from Firestore.
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
            self.footwearOptions = Array(footwearStats.keys)
            print("Loaded footwear from Firestore: \(self.footwearOptions)")
        }
    }
    
    // Add new footwear to Firestore.
    private func addFootwearToFirestore(name: String) {
        guard let userId = AuthService.shared.userSession?.uid else {
            print("User not logged in.")
            return
        }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userId)
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

