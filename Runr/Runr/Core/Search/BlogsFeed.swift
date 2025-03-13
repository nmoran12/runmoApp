//
//  BlogsFeed.swift
//  Runr
//
//  Created by Noah Moran on 13/3/2025.
//

import SwiftUI

struct BlogsFeed: View {
    @ObservedObject var viewModel: ExploreViewModel

    // Filter items with category "Blog"
    var blogs: [ExploreFeedItem] {
        viewModel.exploreFeedItems.filter { $0.category == "Blog" }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(blogs) { item in
                    ExploreFeedCardView(exploreFeedItem: item)
                }
            }
            .padding(.top)
        }
    }
}

#Preview {
    BlogsFeed(viewModel: ExploreViewModel())
}
