//
//  DisplayFootwearHOFRunsView.swift
//  Runr
//
//  Created by Noah Moran on 10/4/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

// A lightweight model representing a run.
struct FootwearRun: Identifiable {
    let id: String
    let date: Date
    let distance: Double
    let elapsedTime: Double
}

@MainActor
class DisplayFootwearHOFRunsViewModel: ObservableObject {
    @Published var runs: [FootwearRun] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    let footwear: String
    
    init(footwear: String) {
        self.footwear = footwear
    }
    
    func fetchRuns() async {
        guard let userId = AuthService.shared.userSession?.uid else {
            errorMessage = "User not logged in."
            isLoading = false
            return
        }
        let db = Firestore.firestore()
        let runsRef = db.collection("users").document(userId).collection("runs")
        
        // Query for runs with a matching "footwear" field, ordered by timestamp descending.
        let query = runsRef
            .whereField("footwear", isEqualTo: footwear)
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
        
        do {
            let snapshot = try await query.getDocuments()
            var fetchedRuns: [FootwearRun] = []
            for doc in snapshot.documents {
                let data = doc.data()
                // Ensure required fields exist.
                guard let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                      let distance = data["distance"] as? Double,
                      let elapsedTime = data["elapsedTime"] as? Double
                else {
                    print("Missing fields for run \(doc.documentID)")
                    continue
                }
                
                let run = FootwearRun(
                    id: doc.documentID,
                    date: timestamp,
                    distance: distance,
                    elapsedTime: elapsedTime
                )
                fetchedRuns.append(run)
            }
            self.runs = fetchedRuns
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct DisplayFootwearHOFRunsView: View {
    let footwear: String
    @StateObject private var viewModel: DisplayFootwearHOFRunsViewModel
    
    init(footwear: String) {
        self.footwear = footwear
        _viewModel = StateObject(wrappedValue: DisplayFootwearHOFRunsViewModel(footwear: footwear))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading runs...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.runs.isEmpty {
                    Text("No runs found for \(footwear).")
                        .foregroundColor(.secondary)
                } else {
                    List(viewModel.runs) { run in
                        VStack(alignment: .leading) {
                            Text("Run on \(run.date, formatter: dateFormatter)")
                                .font(.headline)
                            Text("Distance: \(String(format: "%.2f", run.distance)) km")
                                .font(.subheadline)
                            Text("Time: \(String(format: "%.0f", run.elapsedTime)) sec")
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("\(footwear) Runs")
            .onAppear {
                Task { await viewModel.fetchRuns() }
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

struct DisplayFootwearHOFRunsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DisplayFootwearHOFRunsView(footwear: "Nike Air")
        }
    }
}
