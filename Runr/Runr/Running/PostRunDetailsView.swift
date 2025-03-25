//
//  PostRunDetailsView.swift
//  Runr
//
//  Created by Noah Moran on 13/3/2025.
//

import SwiftUI
import CoreLocation
import FirebaseFirestore

struct PostRunDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var runTracker: RunTracker

    var routeCoordinates: [CLLocationCoordinate2D]
    var distance: Double
    var elapsedTime: Double
    var pace: String
    var footwear: String

    @State private var caption: String = ""
    @State private var showPostAlert: Bool = false
    @State private var postAlertMessage: String = ""
    @State private var userRank: Int? = nil
    
    // Add this to track if we're showing loading state
    @State private var isLoadingRank: Bool = true

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: Map View
                RouteMapView(routeCoordinates: routeCoordinates)
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                    .ignoresSafeArea(edges: .top)
                
                // MARK: Stats Display
                VStack(spacing: 18) {
                    // Leaderboard Status Bar (Styled like music player)
                    HStack {
                        // Trophy icon in circle (like album art)
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 18))
                            )
                            .padding(.leading, 5)
                        
                        // Leaderboard text
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Leaderboard")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                            
                            if isLoadingRank {
                                Text("Loading position...")
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                            } else if let rank = userRank {
                                Text("You are currently #\(rank) on the leaderboard")
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                            } else {
                                Text("Unable to load position")
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Mock player controls for visual consistency
                        HStack(spacing: 20) {
                            
                            Image(systemName: "chevron.right.2")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 10)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.6))
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
                    .padding(.top, 15)
                    
                    // First Stats Row
                    HStack(spacing: 0) {
                        statView(title: "AVG Pace", value: pace, unit: "km")
                        
                        Divider()
                            .frame(height: 50)
                        
                        statView(title: "Distance", value: String(format: "%.2f", distance), unit: "km")
                        
                        Divider()
                            .frame(height: 50)
                        
                        statView(title: "Time", value: formatTime(seconds: Int(elapsedTime)), unit: "")
                    }
                    
                    // Second Stats Row
                    HStack(spacing: 0) {
                        statView(title: "Calories", value: "580", unit: "kcal")
                        
                        Divider()
                            .frame(height: 50)
                        
                        statView(title: "Elevation", value: "12", unit: "m")
                        
                        Divider()
                            .frame(height: 50)
                        
                        statView(title: "BPM", value: "120", unit: "bpm")
                    }
                    
                    // Caption Field
                    TextField("Write a caption...", text: $caption)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
                    Spacer()
                    
                    // Control Buttons moved up substantially to avoid tab bar
                    HStack(spacing: 20) {
                        // Resume button
                        controlButton(systemName: "play.fill", action: {
                            // Resume running action
                            print("Resume run")
                        })
                        
                        // Post Run button (combined with the center button)
                        Button(action: {
                            Task {
                                // Ensure we have the current user's ID
                                guard let userId = AuthService.shared.userSession?.uid else {
                                    print("DEBUG: No user logged in.")
                                    return
                                }
                                
                                // 1. Fetch the current rank before posting the run
                                let oldRank = await fetchUserRank(userId: userId)
                                
                                // 2. Upload the run data
                                await runTracker.uploadRunData(withCaption: caption, footwear: footwear)
                                
                                // 3. Fetch the new rank after upload
                                let newRank = await fetchUserRank(userId: userId)
                                
                                // 4. Calculate positions gained (if any)
                                if let oldRank = oldRank, let newRank = newRank, oldRank > newRank {
                                    let positionsGained = oldRank - newRank
                                    postAlertMessage = "Run was posted successfully! You gained \(positionsGained) position\(positionsGained > 1 ? "s" : "") on the leaderboard."
                                } else {
                                    postAlertMessage = "Run was posted successfully! You did a great run."
                                }
                                
                                // 5. Show the alert
                                showPostAlert = true
                            }
                        }) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Text("Post")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // Timer button
                        controlButton(systemName: "timer", action: {
                            // Timer action
                            print("Timer")
                        })
                    }
                    .padding(.bottom, 120) // Significantly increased to avoid tab bar
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .semibold))
                }
            )
            .navigationBarItems(trailing:
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .semibold))
                }
            )
        }
        .alert("Post Run", isPresented: $showPostAlert) {
            Button("OK", role: .cancel) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(postAlertMessage)
        }
        .onAppear {
            // Fetch the user's current rank when the view appears
            Task {
                guard let userId = AuthService.shared.userSession?.uid else {
                    isLoadingRank = false
                    return
                }
                userRank = await fetchUserRank(userId: userId)
                isLoadingRank = false
            }
        }
    }
    
    // Helper function for displaying stats
    private func statView(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .center, spacing: 5) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // Helper function for control buttons with action parameter
    private func controlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: systemName)
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                )
        }
    }
    
    // Helper function to format time
    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }
}

// Helper async function to fetch the current rank based on "totalDistance"
func fetchUserRank(userId: String) async -> Int? {
    let db = Firestore.firestore()
    do {
        let snapshot = try await db.collection("users")
            .order(by: "totalDistance", descending: true)
            .getDocuments()
        let documents = snapshot.documents
        if let index = documents.firstIndex(where: { $0.documentID == userId }) {
            // Rankings are 1-indexed.
            return index + 1
        }
        return nil
    } catch {
        print("Error fetching leaderboard: \(error.localizedDescription)")
        return nil
    }
}

#Preview {
    PostRunDetailsView(routeCoordinates: [], distance: 5.0, elapsedTime: 600, pace: "5:00 / km", footwear: "Nike Vapor")
        .environmentObject(RunTracker())
}
