//
//  RunningProgramsFeed.swift
//  Runr
//
//  Created by Noah Moran on 13/3/2025.
//

import SwiftUI

struct RunningProgramsFeed: View {
    @ObservedObject var viewModel: ExploreViewModel

    var runningPrograms: [ExploreFeedItem] {
        viewModel.exploreFeedItems.filter { $0.category == "runningProgram" }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(runningPrograms, id: \.exploreFeedId) { item in
                    NavigationLink(destination: RunningProgramContentView(program: RunningProgram(from: item))) {
                        ExploreFeedCardView(exploreFeedItem: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top)
        }
    }
}


#Preview {
    RunningProgramsFeed(viewModel: ExploreViewModel())
}


