//
//  LeaderboardsView.swift
//  Runr
//
//  Created by Noah Moran on 9/1/2025.
//

import SwiftUI

struct LeaderboardsView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    
    var body: some View {
        VStack {
            // Title - Consistent with your FeedView
            HStack {
                Text("Leaderboard")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)

            // Top 3 Users Section
            if viewModel.users.count >= 3 {
                HStack(spacing: 20) {
                    LeaderboardTopUser(user: viewModel.users[1], rank: 2)
                    LeaderboardTopUser(user: viewModel.users[0], rank: 1, isFirst: true) // Middle is 1st place
                    LeaderboardTopUser(user: viewModel.users[2], rank: 3)
                }
                .padding(.vertical, 10)
            }

            Divider().padding(.horizontal)

            // Regular Leaderboard List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.users.indices, id: \.self) { index in
                        LeaderboardsCell(user: viewModel.users[index], rank: index + 1)
                    }
                }
                .padding(.top, 5)
            }
        }
        .onAppear {
            viewModel.fetchLeaderboard()
        }
    }
}


#Preview {
    LeaderboardsView()
}
