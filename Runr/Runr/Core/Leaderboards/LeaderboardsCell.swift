//
//  LeaderboardsCell.swift
//  Runr
//
//  Created by Noah Moran on 9/1/2025.
//

import SwiftUI

struct LeaderboardsCell: View {
    let user: LeaderUser
    let rank: Int
    let leaderboardType: LeaderboardType
    @Environment(\.colorScheme) var colorScheme

    
    private func rankColor() -> Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.2) // Subtle gold
        case 2: return Color.gray.opacity(0.2) // Silver
        case 3: return Color.orange.opacity(0.2) // Bronze
        default: return Color(UIColor.systemGray6)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 30, alignment: .trailing)

            AsyncImage(url: URL(string: user.imageUrl)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 45, height: 45)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 45, height: 45)
                        .clipShape(Circle())
                        .foregroundColor(.secondary)
                }
            }

            Text(user.name)
                .font(.system(size: 18, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Text(user.displayValue(for: leaderboardType))

                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        //.background(rankColor().opacity(0.3))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
    }
}


#Preview {
    LeaderboardsCell(
        user: LeaderUser.MOCK_LEADER_USERS[0],
        rank: 1,
        leaderboardType: .fastest5k
    )
}

