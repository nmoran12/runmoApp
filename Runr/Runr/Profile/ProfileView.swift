//
//  ProfileView.swift
//
//  Created by Noah Moran on 26/12/2024.
//

import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @State var user: User
    @State private var runs: [RunData] = []
    @State private var isLoading = true
    @State private var updateTrigger = false
    @State private var showMenu = false //

    private var totalDistance: Double {
        runs.reduce(0) { $0 + $1.distance } / 1000
    }
    
    private var totalTime: Double {
        runs.reduce(0) { $0 + $1.elapsedTime } / 60
    }
    
    private var averagePace: Double {
        totalDistance > 0 ? totalTime / totalDistance : 0.0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ProfileHeaderView(
                        user: user,
                        totalDistance: totalDistance,
                        totalTime: totalTime,
                        averagePace: averagePace
                    )
                    .id(updateTrigger)
                    
                    if isLoading {
                        ProgressView("Loading runs...")
                    } else if runs.isEmpty {
                        Text("No runs yet")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(runs) { run in
                            RunCell(run: run, userId: user.id)
                        }

                    }
                }
                .padding()
                .onAppear {
                    Task {
                        await fetchUserRuns()
                    }
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
        }
    }

    private func fetchUserRuns() async {
        do {
            try await AuthService.shared.loadUserData()
            self.runs = try await AuthService.shared.fetchUserRuns()
            self.runs.sort { $0.date > $1.date } // Sort runs newest to oldest

            if var currentUser = AuthService.shared.currentUser {
                currentUser.totalDistance = totalDistance
                currentUser.totalTime = totalTime
                currentUser.averagePace = averagePace
                self.user = currentUser
                await updateFirestoreWithStats()
            }
            self.isLoading = false
        } catch {
            self.isLoading = false
        }
    }


    private func updateFirestoreWithStats() async {
        let userRef = Firestore.firestore().collection("users").document(user.id)

        do {
            try await userRef.updateData([
                "totalDistance": totalDistance,
                "totalTime": totalTime,
                "averagePace": averagePace
            ])
            DispatchQueue.main.async {
                updateTrigger.toggle()
            }
        } catch {
            print("Error updating Firestore: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ProfileView(user: User.MOCK_USERS[0])
}
