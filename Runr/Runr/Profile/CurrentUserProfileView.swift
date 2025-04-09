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
    @State private var displayedRunsCount = 5
    
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
                    NavigationStack { // Wrap in a NavigationStack if you wish to keep a title bar, etc.
                        TargetRaceTimeInputView()
                            .environmentObject(NewRunningProgramViewModel()) // You may wish to use the same instance already injected in the app.
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

    // MARK: - MAIN CONTENT (Extracted from body)
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
                    ForEach(runs.prefix(displayedRunsCount)) { run in
                        RunCell(
                            run: run,
                            user: user,
                            isFirst: rankChecker.isFirst,
                            isCurrentUser: Auth.auth().currentUser?.uid == user.id
                        )
                        // When the last run appears, check if there are more to load and then increase the count.
                        .onAppear {
                            if run == runs.prefix(displayedRunsCount).last && displayedRunsCount < runs.count {
                                // Increase by 5 or any other desired increment
                                displayedRunsCount += 5
                            }
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
                
                self.runs = try await AuthService.shared.fetchUserRuns()
                self.runs.sort { $0.date > $1.date }
            }
        } catch {
            print("DEBUG: Failed to load profile data with error \(error.localizedDescription)")
        }
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

