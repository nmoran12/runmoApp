//
//  ExploreFeedCardBlogView.swift
//  Runr
//
//  Created by Noah Moran on 20/2/2025.
//

import SwiftUI

struct ExploreFeedCardRPView: View {
    let exploreFeedItem: ExploreFeedItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: exploreFeedItem.imageUrl)) { image in
                image.resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
            }

            Text(exploreFeedItem.title)
                .font(.headline)

            Text(exploreFeedItem.content)
                .font(.subheadline)
                .lineLimit(3)
                .foregroundColor(.gray)

            Text(exploreFeedItem.category)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
        .padding(.horizontal)
        .frame(width: UIScreen.main.bounds.width * 0.6)

    }
}

#Preview {
    ExploreFeedCardRPView(exploreFeedItem: ExploreFeedItem(
        exploreFeedId: "1",
        title: "How I went from couch to marathon in 6 months",
        content: "This is a story of how I went from couch to marathon in 6 months, working hard and sticking to a plan.",
        category: "Blog",
        imageUrl: "https://via.placeholder.com/200",
        authorId: "sampleUserID",
        authorUsername: "SampleUser"
    ))
}
