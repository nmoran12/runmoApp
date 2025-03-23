//
//  CurrentUserProfileView.swift
//  InstagramTutorial
//
//  Created by Noah Moran on 3/1/2025.
//

import SwiftUI
import FirebaseFirestore

struct CurrentUserProfileView: View {
    @State private var user: User?
    @State private var runs: [RunData] = []
    @State private var totalDistance: Double?
    @State private var totalTime: Double?
    @State private var averagePace: Double?
    @State private var showMenu = false
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var newBio: String = ""
    @State private var showBioAlert = false
    @State private var isFirst = false
    @StateObject private var rankChecker = UserRankChecker()
    @State private var showPrivacyPolicy = false


    var body: some View {
        NavigationStack {
            ScrollView {
                if let user = user {
                    ProfileHeaderView(
                        user: user,
                        totalDistance: totalDistance,
                        totalTime: totalTime,
                        averagePace: averagePace,
                        isFirst: rankChecker.isFirst
                    )

                                            // Button to upload selected image
                                            if let selectedImage {
                                                Button("Upload Image") {
                                                    Task {
                                                        await handleProfileImageUpload(selectedImage)
                                                    }
                                                }
                                                .padding()
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                            }
                    
                    if runs.isEmpty {
                        Text("No runs yet")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(runs) { run in
                            RunCell(run: run, userId: user.id)
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
                Button("Privacy Policy") {
                        showPrivacyPolicy.toggle()
                    }
                Button("Update Bio"){
                    showBioUpdateAlert()
                }
                Button("Sign Out", role: .destructive) {
                    AuthService.shared.signout()
                }
                Button("Cancel", role: .cancel) { }
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
            .task {
                await loadProfileData()
                if let userId = user?.id{
                    await rankChecker.checkIfUserIsFirst(userId: userId)
                }
            }
        }
    }
    
    private func showBioUpdateAlert(){
        showBioAlert = true
    }
    
    private func updateBio(){
        guard let userId = user?.id else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(["bio": newBio]) { error in
            if let error = error {
                print("DEBUG: Failed to update bio - \(error.localizedDescription)")
            } else {
                print("DEBUG: Bio updated successfully")
                DispatchQueue.main.async{
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
                self.runs.sort { $0.date > $1.date } // Sort runs newest to oldest
            }
        } catch {
            print("DEBUG: Failed to load profile data with error \(error.localizedDescription)")
        }
    }
    
    // Function to upload profile image to Firebase
    private func handleProfileImageUpload(_ image: UIImage) async {
        do {
            let imageUrl = try await AuthService.shared.uploadProfileImage(image) // Calls AuthService
            await MainActor.run {
                if var updatedUser = user {
                    updatedUser.profileImageUrl = imageUrl  // Update profile image URL locally
                    self.user = updatedUser
                }
            }
        } catch {
            print("DEBUG: Failed to upload image \(error.localizedDescription)")
        }
    }


}


#Preview {
    CurrentUserProfileView()
}
