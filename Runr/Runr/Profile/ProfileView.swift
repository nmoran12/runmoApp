//
//  ProfileView.swift
//
//  Created by Noah Moran on 26/12/2024.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @Binding var user: User
    @State private var runs: [RunData] = []
    @State private var isLoading = true
    @State private var updateTrigger = false
    @State private var showMenu = false
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isFirst = false
    @StateObject private var rankChecker = UserRankChecker()

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
                mainContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Profile")
                        .fontWeight(.semibold)
                        .font(.system(size: 20))
                }
                ToolbarItem(placement: .topBarTrailing) {
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
    
    /// Break the main VStack into a separate subview for easier compilation.
    @ViewBuilder
    private var mainContent: some View {
        VStack {
            ProfileHeaderView(
                user: user,
                totalDistance: totalDistance,
                totalTime: totalTime,
                averagePace: averagePace,
                isFirst: rankChecker.isFirst
            )
            .id(updateTrigger)
            
            if let selectedImage {
                Button("Upload Image") {
                    Task {
                        do {
                            try await AuthService.shared.uploadProfileImage(selectedImage)
                        } catch {
                            print("DEBUG: Failed to upload image \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            if isLoading {
                ProgressView("Loading runs...")
            } else if runs.isEmpty {
                Text("No runs yet")
                    .font(.footnote)
                    .foregroundColor(.gray)
            } else {
                ForEach(runs) { run in
                    RunCell(
                        run: run,
                        user: user,
                        isFirst: rankChecker.isFirst,
                        isCurrentUser: Auth.auth().currentUser?.uid == user.id
                    )
                }

            }
        }
        .onAppear {
            Task {
                await fetchUserRuns()
                await rankChecker.checkIfUserIsFirst(userId: user.id)
            }
        }
    }

    // MARK: - Fetch user's runs
    private func fetchUserRuns() async {
        do {
            self.runs = try await AuthService.shared.fetchUserRuns(for: user.id)
            self.runs.sort { $0.date > $1.date }
            self.isLoading = false
        } catch {
            self.isLoading = false
            print("DEBUG: Failed to fetch runs for user \(user.id) with error \(error.localizedDescription)")
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
    @State var mockUser = User.MOCK_USERS[0]
    return ProfileView(user: $mockUser)
}

