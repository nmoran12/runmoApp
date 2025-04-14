//
//  FootwearStats.swift
//  Runr
//
//  Created by Noah Moran on 23/3/2025.
//

import SwiftUI
import FirebaseFirestore

struct FootwearStats: View {
    @State private var footwearStats: [String: Double] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Define how many kilometers we recommend before replacing shoes
    private let recommendedMileage: Double = 500.0
    
    // Track which shoes are expanded
    @State private var expandedShoes = Set<String>()
    
    var body: some View {
        // A debug flag to force retire functionality in debug builds.
        #if DEBUG
        let debugForceRetire = true
        #else
        let debugForceRetire = false
        #endif
        
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading footwear stats...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if footwearStats.isEmpty {
                    Text("No footwear stats available.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    // Wrap your content (shoe cards + button) in a single VStack inside ScrollView.
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(footwearStats.keys.sorted(), id: \.self) { footwear in
                                let currentMileage = footwearStats[footwear] ?? 0
                                let progress = min(currentMileage / recommendedMileage, 1.0) // cap at 1.0
                                let isExpanded = expandedShoes.contains(footwear)
                                
                                // Shoe card view
                                VStack(alignment: .leading, spacing: 12) {
                                    // Top row: shoe name and mileage
                                    HStack {
                                        Text("\(footwear): \(String(format: "%.2f", currentMileage)) km")
                                            .font(.headline)
                                        Spacer()
                                        Text(shoeStatus(for: progress))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Progress bar
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.secondary.opacity(0.2))
                                            .frame(height: 10)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(progressColor(progress: progress))
                                            .frame(width: barWidth(for: progress), height: 10)
                                    }
                                    
                                    // Expanded description
                                    if isExpanded {
                                        if progress >= 1.0 {
                                            Text("Your shoes are at the end of their recommended mileage.")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .padding(.top, 4)
                                        } else {
                                            Text("This helps you keep track of the mileage on your shoes so you’ll know when you might need new ones!")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .padding(.top, 4)
                                        }
                                    }
                                    
                                    // Retire button if retire criteria met or forced in debug mode.
                                    if debugForceRetire || progress >= 1.0 {
                                        Button(action: {
                                            retireShoe(footwear)
                                        }) {
                                            Text("Retire")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 12)
                                                .background(Color.red)
                                                .cornerRadius(6)
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
                                .onTapGesture {
                                    withAnimation {
                                        if isExpanded {
                                            expandedShoes.remove(footwear)
                                        } else {
                                            expandedShoes.insert(footwear)
                                        }
                                    }
                                }
                            }
                            
                            // NavigationLink button to view the Footwear Hall of Fame.
                            NavigationLink(destination: FootwearHOFView()) {
                                Text("View Hall of Fame")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }
                        .padding()
                    }
                    .background(Color.white)
                }
            }
            .navigationTitle("Footwear Stats")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchFootwearStats()
            }
        }
    }
    
    // MARK: - Firestore Fetch
    private func fetchFootwearStats() {
        guard let userId = AuthService.shared.userSession?.uid else {
            self.errorMessage = "User not logged in."
            self.isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }
            guard let data = snapshot?.data() else {
                self.errorMessage = "No data found."
                self.isLoading = false
                return
            }
            if let stats = data["footwearStats"] as? [String: Double] {
                self.footwearStats = stats
            } else {
                self.footwearStats = [:]
            }
            self.isLoading = false
        }
    }
    
    // MARK: - UI Helpers
    
    private func progressColor(progress: Double) -> Color {
        switch progress {
        case 0..<0.5: return .green
        case 0.5..<0.9: return .orange
        default: return .red
        }
    }
    
    private func barWidth(for progress: Double) -> CGFloat {
        let maxWidth: CGFloat = 300
        return maxWidth * CGFloat(progress)
    }
    
    private func shoeStatus(for progress: Double) -> String {
        switch progress {
        case 0..<0.2: return "Good as New"
        case 0.2..<0.5: return "Lightly Worn"
        case 0.5..<0.8: return "Moderately Worn"
        case 0.8..<1.0: return "Heavily Worn"
        default: return "Time for new shoes!"
        }
    }
    
    // MARK: - Retire Shoe Functionality
    private func retireShoe(_ footwear: String) {
        guard let userId = AuthService.shared.userSession?.uid else {
            print("User not logged in.")
            return
        }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userId)
        let currentMileage = footwearStats[footwear] ?? 0
        // Store a dictionary with mileage and retiredDate.
        let updates: [String: Any] = [
            "footwearHOF.\(footwear)": [
                "mileage": currentMileage,
                "retiredDate": FieldValue.serverTimestamp()
            ],
            "footwearStats.\(footwear)": FieldValue.delete()
        ]
        docRef.updateData(updates) { (error: Error?) -> Void in
            if let error = error {
                print("Error moving footwear to HOF: \(error)")
            } else {
                withAnimation {
                    _ = self.footwearStats.removeValue(forKey: footwear)
                }
            }
        }
    }
}

struct FootwearStats_Previews: PreviewProvider {
    static var previews: some View {
        FootwearStats()
    }
}
