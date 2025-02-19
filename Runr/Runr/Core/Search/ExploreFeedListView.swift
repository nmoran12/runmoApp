//
//  ExploreFeedListView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI

struct ExploreFeedListView: View {
    @ObservedObject var viewModel: ExploreViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.exploreFeedItems) { item in
                    ExploreFeedCardView(exploreFeedItem: item)
                }
            }
            .padding(.top, viewModel.filteredUsers.isEmpty ? 8 : 0)
        }
    }
}


#Preview {
    ExploreFeedListView(viewModel: ExploreViewModel()) // 🔹 Provide a sample viewModel
}

