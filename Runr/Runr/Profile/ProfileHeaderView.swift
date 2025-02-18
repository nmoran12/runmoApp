//
//  ProfileHeaderView.swift
//  InstagramTutorial
//
//  Created by Noah Moran on 3/1/2025.
//

import SwiftUI

struct ProfileHeaderView: View {
    @EnvironmentObject var authService: AuthService
    
    let user: User
    let totalDistance: Double?
    let totalTime: Double?
    let averagePace: Double?
    
    
    var body: some View {
        VStack {
            // User profile information
            VStack(spacing: 8) {
                if let imageUrl = user.profileImageUrl {
                    Image(imageUrl)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                }
                
                Text(user.username ?? "Unknown Name")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(user.bio ?? "No bio available")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                HStack(spacing: 20) {
                    VStack {
                        Text("\((totalDistance ?? 0) / 1000, specifier: "%.1f") km")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Distance")
                            .font(.caption)
                    }
                    
                    VStack {
                        Text("\(totalTime ?? 0, specifier: "%.0f hrs %.0f mins")")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Time")
                            .font(.caption)
                    }
                    
                    VStack {
                        Text("\(averagePace ?? 0, specifier: "%.1f") min/km")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Average Pace")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ProfileHeaderView(
        user: User(id: "123", username: "Spiderman", email: "spiderman@avengers.com", realName: "Peter Parker"),
        totalDistance: 100.0,
        totalTime: 10.0,
        averagePace: 6.0
    )
    .environmentObject(AuthService.shared) // Inject AuthService for preview
}
