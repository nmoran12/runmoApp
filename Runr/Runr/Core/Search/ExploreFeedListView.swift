//
//  ExploreFeedListView.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import SwiftUI

enum FeedType: String, CaseIterable {
    case runningPrograms = "Running Programs"
    case blogs = "Blogs"
}

struct ExploreFeedListView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @State private var selectedFeed: FeedType = .runningPrograms
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack {

                // Buttons for toggling feed sections
                HStack(spacing: 0) {
                    ForEach(FeedType.allCases, id: \.self) { feed in
                        Button(action: {
                            withAnimation {
                                selectedFeed = feed
                            }
                        }) {
                            Text(feed.rawValue)
                                .font(.headline)
                                .foregroundColor(selectedFeed == feed ? .black : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                // Show the selected feed
                if selectedFeed == .runningPrograms {
                    RunningProgramsFeed(viewModel: viewModel)
                } else {
                    BlogsFeed(viewModel: viewModel)
                }
            }
        }
    }
}

#Preview {
    ExploreFeedListView(viewModel: ExploreViewModel())
}


