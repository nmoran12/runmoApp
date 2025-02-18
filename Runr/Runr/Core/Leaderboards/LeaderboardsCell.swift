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
    
    // Function to determine rank color
    private func rankColor() -> Color {
        switch rank {
        case 1: return Color.yellow // 1st place colour
        case 2: return Color.gray // second place colour
        case 3: return Color.orange // third place colour
        default: return Color(.systemGray6) // colour for generic position
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 30, alignment: .trailing)

            AsyncImage(url: URL(string: user.imageUrl)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 45, height: 45)
                        .clipShape(Circle())
                } else if phase.error != nil {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 45, height: 45)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                } else {
                    ProgressView()
                        .frame(width: 45, height: 45)
                }
            }

            Text(user.name)
                .font(.system(size: 20))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Text("\(user.totalDistance / 1000, specifier: "%.2f") km")
                .font(.system(size: 20, weight: .medium))
                .monospacedDigit()
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(rankColor().opacity(0.3)) // Adds color background for top 3
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#Preview {
    LeaderboardsCell(
        user: LeaderUser.MOCK_LEADER_USERS[0],
        rank: 1
    )
}
