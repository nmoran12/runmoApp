//
//  LeaderboardTopUser.swift
//  Runr
//
//  Created by Noah Moran on 12/3/2025.
//

import SwiftUI

struct LeaderboardTopUser: View {
    let user: LeaderUser
    let rank: Int
    var isFirst: Bool = false
    let leaderboardType: LeaderboardType
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if rank == 1 {
                ChampionHighlightView {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(colorScheme == .dark ? 0.3 : 0.2))
                            .frame(width: 80, height: 80)
                        
                        userProfileImage
                        
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .offset(y: -40)
                    }
                }
                .frame(width: 120, height: 120)
            } else {
                ZStack {
                    Circle()
                        .fill(rank == 2 ?
                              (colorScheme == .dark ? Color.gray.opacity(0.3) : Color.secondary.opacity(0.2)) :
                              (colorScheme == .dark ? Color.orange.opacity(0.3) : Color.orange.opacity(0.2)))
                    
                    userProfileImage
                    if isFirst {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .offset(y: -40)
                    }
                }
            }
            
            Text(user.name)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Text(user.displayValue(for: leaderboardType))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(width: 90)
    }
    
    private var userProfileImage: some View {
        AsyncImage(url: URL(string: user.imageUrl)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: isFirst ? 75 : 65, height: isFirst ? 75 : 65)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: isFirst ? 75 : 65, height: isFirst ? 75 : 65)
                    .clipShape(Circle())
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LeaderboardTopUser_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardTopUser(
            user: LeaderUser.MOCK_USER,
            rank: 1,
            leaderboardType: .fastest5k
        )
    }
}




