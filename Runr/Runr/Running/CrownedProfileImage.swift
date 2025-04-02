//
//  CrownedProfileImage.swift
//  Runr
//
//  Created by Noah Moran on 28/3/2025.
//

import SwiftUI
import Kingfisher

struct CrownedProfileImage: View {
    var profileImageUrl: String?
    var size: CGFloat = 80
    var isFirst: Bool = false

    var body: some View {
        
        // Decide if this is a "small" or "large" icon
                let isSmall = size < 40
                let outerSize = size
                let imageSize = isFirst ? size - 10 : size  // Only reduce size if isFirst is true.
                // Dynamically pick values based on isSmall
                let ringLineWidth: CGFloat = isSmall ? 2 : 4
        
        ZStack {
                    // Outer circle (golden ring if isFirst)
                    Circle()
                        .stroke(isFirst ? Color.yellow : Color.clear, lineWidth: ringLineWidth)
                        .frame(width: outerSize, height: outerSize)
                    
                    // Profile image
                    if let profileImageUrl = profileImageUrl, let url = URL(string: profileImageUrl) {
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageSize, height: imageSize)
                            .clipShape(Circle())
                          //  .overlay(
                          //      Circle()
                          //          .stroke(Color.primary, lineWidth: isFirst ? 2 : 0)
                          //  )
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageSize - 10, height: imageSize - 10)
                            .clipShape(Circle())
                            .foregroundColor(.secondary)
                    }
                    
                    // Crown overlay for champion
                    if isFirst {
                        Image(systemName: "crown.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: outerSize / 3, height: outerSize / 3)
                            .foregroundColor(.yellow)
                            .offset(y: -outerSize * 0.63)
                    }
                }
            }
        }

        #Preview {
            Group {
                // Preview for champion image
                CrownedProfileImage(profileImageUrl: "https://example.com/profile.jpg", size: 80, isFirst: true)
                    .previewDisplayName("Champion (isFirst true)")
                
                // Preview for regular image
                CrownedProfileImage(profileImageUrl: "https://example.com/profile.jpg", size: 80, isFirst: false)
                    .previewDisplayName("Regular (isFirst false)")
            }
        }
