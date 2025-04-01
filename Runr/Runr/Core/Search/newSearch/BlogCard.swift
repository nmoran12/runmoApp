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
    // Closure to be called when the user taps “Save” from the context menu.
        var onSave: (() async -> Void)? = nil
    
    @Environment(\.colorScheme) var colorScheme
    // Adjust these constants to your preference
    private let cardWidth: CGFloat = 200
    private let cardHeight: CGFloat = 260
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: URL(string: blog.imageUrl)) { phase in
                switch phase {
                case .empty:
                    // While loading, show a placeholder or ProgressView
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: cardWidth, height: cardHeight)
                    
                case .success(let downloadedImage):
                    // If the download succeeds, show the actual image
                    downloadedImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                    
                case .failure(_):
                    // If there’s an error, show a fallback
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: cardWidth, height: cardHeight)
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.primary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: cardWidth, height: cardHeight)
                    .onAppear {
                        print("BlogCard imageUrl:", blog.imageUrl)
                    }

            
            // Dark gradient overlay
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: cardWidth, height: cardHeight)

            
            // Overlaid text
            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                
                Text(blog.snippet)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .light ? .white : .primary)
                Text(blog.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .light ? .white : .primary.opacity(0.9))
            }
            .padding()
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.primary.opacity(0.2), radius: 4, x: 0, y: 3)
        .contextMenu {
        if let onSave = onSave {
            Button("Save") {
                Task {
                    await onSave()
                }
            }
        }
    }
    }
    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [Color.black.opacity(0.2), Color.black.opacity(0.8)]
        } else {
            return [Color.black.opacity(0.4), Color.black.opacity(0.7)]
        }
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
