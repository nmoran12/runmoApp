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
            // 🔹 Running Programs Section (Horizontal Scroll)
            let runningPrograms = viewModel.exploreFeedItems.filter { $0.category == "Running_Program" }

            if !runningPrograms.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(runningPrograms) { item in
                            ExploreFeedCardRPView(exploreFeedItem: item)
                        }
                    }
                }
                .frame(height: 320)
            } else {
                Text("No Running Programs Available")
                    .foregroundColor(.gray)
                    .padding()
            }

            Divider() // Visual separation between sections

            // 🔹 Blog Posts Section (Vertical Scroll)
            LazyVStack(spacing: 16) {
                ForEach(viewModel.exploreFeedItems.filter { $0.category == "Blog" }) { item in
                    ExploreFeedCardView(exploreFeedItem: item)
                }
            }
            .padding(.top, viewModel.filteredUsers.isEmpty ? 8 : 0)
        }
    }
}

#Preview {
    ExploreFeedListView(viewModel: ExploreViewModel())
}



