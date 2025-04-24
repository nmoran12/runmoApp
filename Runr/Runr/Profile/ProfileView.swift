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
    @Environment(\.dismiss) var dismiss
    
    // Pagination state
    @State private var lastRunDocument: DocumentSnapshot? = nil
    @State private var loadingMore: Bool = false
    @State private var reachedEnd: Bool = false

    // Determine if the profile belongs to the current user.
        private var isCurrentUser: Bool {
            Auth.auth().currentUser?.uid == user.id
        }
    
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
        // 1) Build the core VStack once and store in a local constant
        let layout = VStack(spacing: 0) {
            if !isCurrentUser {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Text(user.username ?? "Profile")
                        .font(.headline)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color(.systemBackground))
            }

            ScrollView {
                mainContent
            }
        }

        // 2) For other users, wrap in a ZStack that fills the top safe area
            return Group {
                if !isCurrentUser {
                    ZStack(alignment: .top) {
                        // fills behind the notch with systemBackground
                        Color(.systemBackground)
                            .ignoresSafeArea(edges: .top)
                        layout
                    }
                } else {
                    layout
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await loadInitialRuns()
                await rankChecker.checkIfUserIsFirst(userId: user.id)
            }
        }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack {
            ProfileHeaderView(
                user: user,
                totalDistance: totalDistance,
                totalTime: totalTime,
                averagePace: averagePace,
                isFirst: rankChecker.isFirst,
                runs: runs
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
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(runs) { run in
                        RunCell(
                            run: run,
                            user: user,
                            isFirst: rankChecker.isFirst,
                            isCurrentUser: isCurrentUser
                        )
                        .onAppear {
                            // only when the very last loaded run scrolls into view...
                            if run == runs.last, !reachedEnd {
                                Task { await loadMoreRuns() }
                            }
                        }
                    }
                    
                    if loadingMore {
                        ProgressView("Loading more runs…")
                            .padding()
                    }
                }
                
            }
        }
    }
    
    private func loadInitialRuns() async {
            isLoading = true
            do {
                let (firstPage, lastDoc) = try await AuthService.shared
                    .fetchUserRunsPaginated(
                        for: user.id,
                        lastDocument: nil,
                        limit: 7
                    )
                runs = firstPage.sorted { $0.date > $1.date }
                lastRunDocument = lastDoc
                reachedEnd = firstPage.count < 7
            } catch {
                print("DEBUG: Failed to load runs for \(user.id) — \(error)")
            }
            isLoading = false
        }

        private func loadMoreRuns() async {
            guard !loadingMore, !reachedEnd, let lastDoc = lastRunDocument else { return }
            loadingMore = true
            do {
                let (nextPage, newLast) = try await AuthService.shared
                    .fetchUserRunsPaginated(
                        for: user.id,
                        lastDocument: lastDoc,
                        limit: 7
                    )
                let sorted = nextPage.sorted { $0.date > $1.date }
                runs.append(contentsOf: sorted)
                lastRunDocument = newLast
                if nextPage.count < 7 { reachedEnd = true }
            } catch {
                print("DEBUG: Failed to load more runs — \(error)")
            }
            loadingMore = false
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

