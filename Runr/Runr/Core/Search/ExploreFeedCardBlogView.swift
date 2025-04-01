//
//  ExploreFeedCardView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI

struct ExploreFeedCardView: View {
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
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 200)
            }

            Text(exploreFeedItem.title)
                .font(.headline)

            Text(exploreFeedItem.content)
                .font(.subheadline)
                .lineLimit(3)
                .foregroundColor(.secondary)

            Text(exploreFeedItem.category)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.primary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}


#Preview {
    ExploreFeedCardView(exploreFeedItem: ExploreFeedItem(
        exploreFeedId: "1", // 🔹 Use the correct parameter name
        title: "5K Beginner Plan",
        content: "A structured 5K training plan to get started with running.",
        category: "Running Program",
        imageUrl: "https://via.placeholder.com/200",
        authorId: "sampleUserID",
        authorUsername: "SampleUser"
    ))
}


