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
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(isFirst ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: isFirst ? 80 : 70, height: isFirst ? 80 : 70)

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
                            .foregroundColor(.gray)
                    }
                }
                
                if isFirst {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .offset(y: -40)
                }
            }

            Text(user.name)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(1)
                .truncationMode(.tail)

            Text("\(user.totalDistance, specifier: "%.2f") km")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(width: 90)
    }
}


#Preview {
    LeaderboardTopUser(user: LeaderUser.MOCK_USER, rank: 1)
}

