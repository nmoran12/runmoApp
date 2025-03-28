//
//  ProfileImagePreviewView.swift
//  Runr
//
//  Created by Noah Moran on 28/3/2025.
//

import SwiftUI

struct ProfileImagePreviewView: View {
    @Binding var image: UIImage?
    let onUpload: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Spacer().frame(height: 40)  // Extra top space

                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            // We already added a Spacer, so no extra .padding needed here

                        Text("Preview of your new profile picture")
                            .font(.headline)

                        Button("Upload Image") {
                            onUpload()
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)

                        Button("Cancel") {
                            onCancel()
                        }

                        Spacer().frame(height: 40) // Extra bottom space
                    } else {
                        Text("No image selected.")
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ProfileImagePreviewView(
        image: .constant(UIImage(systemName: "person.circle.fill")),
        onUpload: {
            print("Upload tapped in preview")
        },
        onCancel: {
            print("Cancel tapped in preview")
        }
    )
}


