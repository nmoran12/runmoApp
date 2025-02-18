//
//  CurrentUserProfileView.swift
//  InstagramTutorial
//
//  Created by Noah Moran on 3/1/2025.
//

import SwiftUI

struct CurrentUserProfileView: View {
    @State private var user: User?
    @State private var runs: [RunData] = []
    @State private var totalDistance: Double?
    @State private var totalTime: Double?
    @State private var averagePace: Double?
    @State private var showMenu = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let user = user {
                    ProfileHeaderView(
                        user: user,
                        totalDistance: totalDistance,
                        totalTime: totalTime,
                        averagePace: averagePace
                    )
                    
                    if runs.isEmpty {
                        Text("No runs yet")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(runs) { run in
                            RunCell(run: run)
                        }
                    }
                } else {
                    ProgressView("Loading profile...")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showMenu.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
            }
            .confirmationDialog("Menu", isPresented: $showMenu, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    AuthService.shared.signout()
                }
                Button("Cancel", role: .cancel) { }
            }
            .task {
                await loadProfileData()
            }
        }
    }
    
    private func loadProfileData() async {
        do {
            try await AuthService.shared.loadUserData()
            if let currentUser = AuthService.shared.currentUser {
                self.user = currentUser
                self.totalDistance = currentUser.totalDistance
                self.totalTime = currentUser.totalTime
                self.averagePace = currentUser.averagePace
                
                self.runs = try await AuthService.shared.fetchUserRuns()
            }
        } catch {
            print("DEBUG: Failed to load profile data with error \(error.localizedDescription)")
        }
    }
}


#Preview {
    CurrentUserProfileView()
}
