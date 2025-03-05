//
//  RunCell.swift
//  Runr
//
//  Created by Noah Moran on 15/1/2025.
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct RunCell: View {
    var run: RunData
    var userId: String // To track which user's run this is
    
    @State private var showDetailView = false
    @State private var showMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run.circle")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text("Run")
                        .font(.headline)
                    Text(run.date, formatter: dateFormatter)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Ellipsis Button for Menu
                Button(action: {
                    showMenu.toggle()
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .confirmationDialog("Run Options", isPresented: $showMenu, titleVisibility: .visible) {
                    Button("Delete Run", role: .destructive) {
                        deleteRun()
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
            .padding(.horizontal)

            // Navigation to RunDetailView
            NavigationLink(destination: RunDetailView(run: run, userId: userId), isActive: $showDetailView) {
                EmptyView()
            }
            .hidden()

            // Running Stats
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distance:")
                        .fontWeight(.semibold)
                    Text(String(format: "%.2f km", run.distance / 1000))
                }
                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Time:")
                        .fontWeight(.semibold)
                    let timeMinutes = Int(run.elapsedTime) / 60
                    let timeSeconds = Int(run.elapsedTime) % 60
                    Text(String(format: "%d min %02d sec", timeMinutes, timeSeconds))
                }
                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pace:")
                        .fontWeight(.semibold)
                    let paceInSecondsPerKm = run.elapsedTime / (run.distance / 1000)
                    let paceMinutes = Int(paceInSecondsPerKm) / 60
                    let paceSeconds = Int(paceInSecondsPerKm) % 60
                    Text(String(format: "%d:%02d / km", paceMinutes, paceSeconds))
                }
            }
            .font(.footnote)
            .padding(.horizontal)

            // Route Map
            if !run.routeCoordinates.isEmpty {
                RouteMapView(routeCoordinates: run.routeCoordinates)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, 6)
            }

            Divider()
        }
        .padding(.vertical)
        .onTapGesture {
            showDetailView = true
        }
    }

    // Function to delete the run
    private func deleteRun() {
        let db = Firestore.firestore()
        let runRef = db.collection("users").document(userId).collection("runs").document(run.id)
        
        runRef.delete { error in
            if let error = error {
                print("Error deleting run: \(error.localizedDescription)")
            } else {
                print("Run deleted successfully!")
            }
        }
    }

    // Date formatter for displaying the run date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

#Preview {
    RunCell(run: RunData(date: Date(), distance: 5000, elapsedTime: 1800, routeCoordinates: []), userId: "testUser")
}
