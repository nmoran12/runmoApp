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
        NavigationView {
            VStack {
                // Search Bar
                TextField("Search", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // Feed Toggle Buttons
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
                                .padding(.vertical, 10)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Display Selected Feed
                if selectedFeed == .runningPrograms {
                    RunningProgramsFeed(viewModel: viewModel)
                } else {
                    BlogsFeed(viewModel: viewModel)
                }
                
                Spacer()
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ExploreFeedListView(viewModel: ExploreViewModel())
}



