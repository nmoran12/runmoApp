//
//  BlogCard.swift
//  Runr
//
//  Created by Noah Moran on 24/3/2025.
//

import SwiftUI

/// Card for Blogs (horizontal carousel as well).
struct BlogCard: View {
    let blog: Blog123
    
    // Adjust these constants to your preference
    private let cardWidth: CGFloat = 200
    private let cardHeight: CGFloat = 260
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: URL(string: blog.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: cardWidth, height: cardHeight)
            }
            
            // Dark gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.6)
                ]),
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(width: cardWidth, height: cardHeight)
            
            // Overlaid text
            VStack(alignment: .leading, spacing: 4) {
                Text(blog.snippet)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(blog.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 3)
    }
}

struct BlogCard_Previews: PreviewProvider {
    static var previews: some View {
        BlogCard(
            blog: Blog123(
                title: "Sample Title",
                snippet: "Sample snippet for the blog preview.",
                imageUrl: "https://via.placeholder.com/400x200"
            )
        )
        .previewLayout(.sizeThatFits)
    }
}
