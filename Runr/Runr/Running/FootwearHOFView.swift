//
//  FootwearHOFView.swift
//  Runr
//
//  Created by Noah Moran on 10/4/2025.
//

import SwiftUI
import FirebaseFirestore

struct RetiredShoe: Identifiable {
    let id: String            // the shoe name
    let mileage: Double
    let retiredDate: Date?
    
    func formattedRetirementDate() -> String {
        if let date = retiredDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        } else {
            return "Unknown"
        }
    }
}

struct FootwearHOFView: View {
    @State private var hofShoes: [RetiredShoe] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading Hall of Fame...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if hofShoes.isEmpty {
                Text("No retired footwear yet.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(hofShoes) { shoe in
                            // Wrap each shoe cell in a NavigationLink
                            NavigationLink(destination: DisplayFootwearHOFRunsView(footwear: shoe.id)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(shoe.id)
                                        .font(.headline)
                                    Text("\(String(format: "%.2f", shoe.mileage)) km total")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Retired: \(shoe.formattedRetirementDate())")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Footwear Hall of Fame")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchHOFStats()
        }
    }
    
    private func fetchHOFStats() {
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
                print("Error fetching document: \(error)")
                return
            }
            guard let data = snapshot?.data() else {
                self.errorMessage = "No data found."
                self.isLoading = false
                print("No data found in document")
                return
            }
            print("Fetched user document data: \(data)")
            if let hofAny = data["footwearHOF"] as? [String: Any] {
                let shoes: [RetiredShoe] = hofAny.compactMap { (shoeName, value) in
                    if let info = value as? [String: Any] {
                        let mileage = info["mileage"] as? Double ?? 0
                        var retiredDate: Date? = nil
                        if let timestamp = info["retiredDate"] as? Timestamp {
                            retiredDate = timestamp.dateValue()
                        } else {
                            print("No valid timestamp for shoe: \(shoeName)")
                        }
                        return RetiredShoe(id: shoeName, mileage: mileage, retiredDate: retiredDate)
                    } else {
                        print("Value for key \(shoeName) is not a dictionary")
                        return nil
                    }
                }
                self.hofShoes = shoes.sorted { $0.id < $1.id }
            } else {
                print("No footwearHOF field found or wrong structure")
                self.hofShoes = []
            }
            self.isLoading = false
        }
    }
}

struct FootwearHOFView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FootwearHOFView()
        }
    }
}
