//
//  CurrentUserProfileView.swift
//  InstagramTutorial
//
//  Created by Noah Moran on 3/1/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CurrentUserProfileView: View {
    @State private var user: User?
    @State private var runs: [RunData] = []
    @State private var totalDistance: Double?
    @State private var totalTime: Double?
    @State private var averagePace: Double?
    @State private var showMenu = false
    
    // Pagination state variables
    @State private var lastRunDocument: DocumentSnapshot? = nil
    @State private var loadingMore: Bool = false
    @State private var reachedEnd: Bool = false
    
    // Image Selection States
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isPreviewPresented = false
    
    @State private var newBio: String = ""
    @State private var showBioAlert = false
    @State private var isFirst = false
    @StateObject private var rankChecker = UserRankChecker()
    @State private var showPrivacyPolicy = false
    @State private var showSavedItemsView = false
    @State private var showCalendarView = false
    
    @State private var showTargetRaceTimeUpdate: Bool = false

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showMenu.toggle()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .confirmationDialog("Menu", isPresented: $showMenu, titleVisibility: .visible) {
                    Button("Update Target Race Time") {
                        showTargetRaceTimeUpdate.toggle()
                    }
                    Button("Calendar") {
                        showCalendarView = true
                    }
                    Button("View Saved") {
                        showSavedItemsView = true
                    }
                    Button("Privacy Policy") {
                        showPrivacyPolicy.toggle()
                    }
                    Button("Update Bio") {
                        showBioUpdateAlert()
                    }
                    Button("Sign Out", role: .destructive) {
                        AuthService.shared.signout()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                // Sheets & alerts
                .sheet(isPresented: $showCalendarView) {
                    CalendarView(runs: runs)
                }
                .sheet(isPresented: $showPrivacyPolicy) {
                    NavigationStack {
                        PrivacyPolicyView()
                    }
                }
                .alert("Update Bio", isPresented: $showBioAlert) {
                    TextField("Enter new bio", text: $newBio)
                    Button("Save", action: updateBio)
                    Button("Cancel", role: .cancel) { }
                }
                // Image picker
                .sheet(isPresented: $isImagePickerPresented, onDismiss: {
                    if selectedImage != nil {
                        isPreviewPresented = true
                    }
                }) {
                    ImagePicker(image: $selectedImage)
                }
                // Preview view
                .sheet(isPresented: $isPreviewPresented) {
                    ProfileImagePreviewView(
                        image: $selectedImage,
                        onUpload: {
                            Task {
                                await handleProfileImageUpload()
                                isPreviewPresented = false
                            }
                        },
                        onCancel: {
                            selectedImage = nil
                            isPreviewPresented = false
                        }
                    )
                }
                .sheet(isPresented: $showTargetRaceTimeUpdate) {
                    NavigationStack {
                        TargetRaceTimeInputView()
                            .environmentObject(NewRunningProgramViewModel())
                            .navigationTitle("Update Target Race Time")
                    }
                }
                .task {
                    await loadProfileData()
                    if let userId = user?.id {
                        await rankChecker.checkIfUserIsFirst(userId: userId)
                    }
                }
        }
    }
    
    // MARK: - MAIN CONTENT
    private var mainContent: some View {
        ScrollView {
            if let user = user {
                ProfileHeaderView(
                    user: user,
                    totalDistance: totalDistance,
                    totalTime: totalTime,
                    averagePace: averagePace,
                    isFirst: rankChecker.isFirst,
                    runs: runs,
                    onTapProfileImage: {
                        isImagePickerPresented = true
                    }
                )
                if runs.isEmpty {
                    Text("No runs yet")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    // Use LazyVStack for efficient rendering of many cells.
                    LazyVStack {
                        ForEach(runs) { run in
                            RunCell(
                                run: run,
                                user: user,
                                isFirst: rankChecker.isFirst,
                                isCurrentUser: Auth.auth().currentUser?.uid == user.id
                            )
                            .onAppear {
                                // When the last run is about to appear, trigger loading more runs.
                                if run == runs.last && !reachedEnd {
                                    Task {
                                        await loadMoreRuns()
                                    }
                                }
                            }
                        }
                        if loadingMore {
                            ProgressView("Loading more runs...")
                                .padding()
                        }
                    }
                }
            } else {
                ProgressView("Loading profile...")
            }
        }
    }
    
    // MARK: - FUNCTIONS
    
    private func showBioUpdateAlert() {
        showBioAlert = true
    }
    
    private func updateBio() {
        guard let userId = user?.id else { return }
        Firestore.firestore().collection("users").document(userId)
            .updateData(["bio": newBio]) { error in
                if let error = error {
                    print("DEBUG: Failed to update bio - \(error.localizedDescription)")
                } else {
                    print("DEBUG: Bio updated successfully")
                    DispatchQueue.main.async {
                        user?.bio = newBio
                    }
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
                
                // Load the first page (7 runs) using the paginated method.
                let (fetchedRuns, lastDoc) = try await AuthService.shared.fetchUserRunsPaginated(lastDocument: nil, limit: 7)
                self.runs = fetchedRuns.sorted { $0.date > $1.date }
                self.lastRunDocument = lastDoc
                if fetchedRuns.count < 7 {
                    reachedEnd = true
                }
            }
        } catch {
            print("DEBUG: Failed to load profile data with error \(error.localizedDescription)")
        }
    }
    
    private func loadMoreRuns() async {
        guard !loadingMore, !reachedEnd, let lastRunDoc = lastRunDocument else { return }
        loadingMore = true
        do {
            let (moreRuns, newLastDoc) = try await AuthService.shared.fetchUserRunsPaginated(lastDocument: lastRunDoc, limit: 7)
            let sortedNewRuns = moreRuns.sorted { $0.date > $1.date }
            self.runs.append(contentsOf: sortedNewRuns)
            self.lastRunDocument = newLastDoc
            if moreRuns.count < 7 {
                reachedEnd = true
            }
        } catch {
            print("DEBUG: Failed to load more runs with error \(error.localizedDescription)")
        }
        loadingMore = false
    }
    
    private func handleProfileImageUpload(_ image: UIImage? = nil) async {
        let imageToUpload = image ?? selectedImage
        guard let imageToUpload else { return }
        do {
            let imageUrl = try await AuthService.shared.uploadProfileImage(imageToUpload)
            await MainActor.run {
                if var updatedUser = user {
                    updatedUser.profileImageUrl = imageUrl
                    self.user = updatedUser
                }
                selectedImage = nil
            }
        } catch {
            print("DEBUG: Failed to upload image \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
#Preview {
    CurrentUserProfileView()
}
