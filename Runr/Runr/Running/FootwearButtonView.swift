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
        .zIndex(1) // Ensure button stays above other content
        .overlay(
            Group {
                if showFootwearMenu {
                    footwearMenuView
                        .offset(x: -160, y: -150) // Adjust for proper positioning
                        .transition(.opacity)
                        .onAppear {
                            loadFootwearFromFirestore()
                        }
                }
            },
            alignment: .center // Center alignment gives more predictable positioning
        )
    }
    
    // Extracted menu view for better organization
    private var footwearMenuView: some View {
        VStack(spacing: 12) {
            // Search bar
            TextField("Search or add new footwear...", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .cornerRadius(12)
                .padding(.top, 8)
                .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
            
            // Footwear list with scrollable content
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredFootwearOptions(), id: \.self) { option in
                        HStack {
                            Text(option)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFootwear = option
                            showFootwearMenu = false
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteFootwear(option)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        Divider()
                    }
                }
            }
            .frame(height: 200)
            
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
                    .cornerRadius(12)
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
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 12)
        .frame(width: 300) // Fixed width to ensure proper display
        .background(.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
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
    NavigationView {
        FootwearButtonView(selectedFootwear: $previewFootwear)
    }
}
