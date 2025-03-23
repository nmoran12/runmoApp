//
//  BlogContentView.swift
//  Runr
//
//  Created by Noah Moran on 23/3/2025.
//

import SwiftUI

struct BlogContentView: View {
    let blog: ExploreFeedItem

    var body: some View {
        ScrollView {
            AsyncImage(url: URL(string: blog.imageUrl)) { image in
                Image("DefaultPlaceholder")
                            .resizable()
                            .scaledToFill()
            }
            .frame(width: UIScreen.main.bounds.width,
                   height: UIScreen.main.bounds.height * 0.6)
            .clipped()

            // Title
            Text(blog.title)
                .fontWeight(.semibold)
                .font(.system(size: 32))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 20)
            
            // Author
            Text("Author: \(blog.authorUsername ?? "Unknown")")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 20)

            // Full content
            Text(blog.content)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 20)

            // Category
            Text("Category: \(blog.category)")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 8)
        }
        .padding()
        .ignoresSafeArea(edges: .top)
        .navigationTitle("Blog Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    BlogContentView(blog: ExploreFeedItem(
        exploreFeedId: "preview-blog",
        title: "Preview Title",
        content: "Some blog content for the preview.",
        category: "Blog",
        imageUrl: "https://via.placeholder.com/200",
        authorId: "sampleUserID",
        authorUsername: "SampleUser"
    ))
}

