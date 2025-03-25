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
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(footwearStats.keys.sorted(), id: \.self) { footwear in
                                let currentMileage = footwearStats[footwear] ?? 0
                                let progress = min(currentMileage / recommendedMileage, 1.0) // cap at 1.0
                                let isExpanded = expandedShoes.contains(footwear)
                                
                                // One "card" or "row" per shoe
                                VStack(alignment: .leading, spacing: 12) {
                                    // Top line with shoe name & current mileage
                                    HStack {
                                        Text("\(footwear): \(String(format: "%.2f", currentMileage)) km")
                                            .font(.headline)
                                        Spacer()
                                        // The status text on the right
                                        Text(shoeStatus(for: progress))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Color-coded progress bar
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 10)
                                        
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(progressColor(progress: progress))
                                            .frame(width: barWidth(for: progress), height: 10)
                                    }
                                    
                                    // Pop-down description when expanded
                                    if isExpanded {
                                        Text("This helps you keep track of the mileage on your shoes so you’ll know when you might need new ones!")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .padding(.top, 4)
                                    }
                                }
                                .padding()
                                .background(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                // Tap gesture toggles expansion
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
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
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
    
    // Returns a color for the progress bar based on how close the shoe is to 100%.
    private func progressColor(progress: Double) -> Color {
        switch progress {
        case 0..<0.5:
            return .green
        case 0.5..<0.9:
            return .orange
        default:
            return .red
        }
    }
    
    /// Calculates the width for the colored portion of the progress bar.
    private func barWidth(for progress: Double) -> CGFloat {
        let maxWidth: CGFloat = 300
        return maxWidth * CGFloat(progress)
    }
    
    /// Returns a status string
    private func shoeStatus(for progress: Double) -> String {
        switch progress {
        case 0..<0.2:
            return "Good as New"
        case 0.2..<0.5:
            return "Lightly Worn"
        case 0.5..<0.8:
            return "Moderately Worn"
        case 0.8..<1.0:
            return "Heavily Worn"
        default:
            return "Time for new shoes!"
        }
    }
}


struct FootwearStats_Previews: PreviewProvider {
    static var previews: some View {
        FootwearStats()
    }
}

