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
    let user: User            // Now we have the full user object
    let isFirst: Bool         // So we can show the crown
    var isCurrentUser: Bool
    
    @State private var showDetailView = false
    @State private var showMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CrownedProfileImage(
                    profileImageUrl: user.profileImageUrl,
                    size: 40,
                    isFirst: isFirst
                )
                
                VStack(alignment: .leading) {
                    Text(user.username)
                        .font(.headline)
                    Text(run.date, formatter: dateFormatter)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Ellipsis Button for Menu
                Button(action: {
                    showMenu.toggle()
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .confirmationDialog("Run Options", isPresented: $showMenu, titleVisibility: .visible) {
                    // Show "Delete Run" only if this is the current user's run.
                    if isCurrentUser {
                        Button("Delete Run", role: .destructive) {
                            deleteRun()
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
            .padding(.horizontal)

            // Navigation to RunDetailView
            NavigationLink(destination: RunDetailView(run: run, userId: user.id), isActive: $showDetailView) {
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
                    .allowsHitTesting(false)  // Disable interaction on the map
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
        let runRef = db.collection("users").document(user.id).collection("runs").document(run.id)
        
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
    // For preview purposes, using a mock user from your MOCK_USERS array.
    RunCell(
        run: RunData(date: Date(), distance: 5000, elapsedTime: 1800, routeCoordinates: []),
        user: User.MOCK_USERS[0],
        isFirst: true,
        isCurrentUser: true
    )
}

