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
                
                // Dynamically pick values based on isSmall
                let strokeWidth: CGFloat = isSmall ? 2 : 4
        
        ZStack {
            // Outer circle with crown stroke if first
            Circle()
                .stroke(isFirst ? Color.yellow : Color.clear, lineWidth: strokeWidth)
                .frame(width: size, height: size)
            
            // Profile image
            if let profileImageUrl = profileImageUrl,
               let url = URL(string: profileImageUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    // Subtract a few points to show the stroke
                    .frame(width: size - 10, height: size - 10)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size - 10, height: size - 10)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
            }
            
            // Crown if first; adjust the offset as needed
            if isFirst {
                Image(systemName: "crown.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size / 3, height: size / 3)
                    .foregroundColor(.yellow)
                    .offset(y: -size * 0.63)
            }
        }
    }
}


#Preview {
    CrownedProfileImage()
}
