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
            Text("🏆 Leaderboards")
                .font(.system(size: 32, weight: .bold))
                .padding(.top, 10)
            
            Divider()
                .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.users.indices, id: \.self) { index in
                        LeaderboardsCell(user: viewModel.users[index], rank: index + 1)
                    }
                }
                .padding(.top, 10)
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
