//
//  User.swift
//  InstagramTutorial
//
//  Created by Noah Moran on 3/1/2025.
//

import Foundation

struct User: Identifiable, Hashable, Codable{
    let id: String
    var username: String
    var profileImageUrl: String?
    var fullname: String?
    var bio: String?
    let email: String
    var realName: String?
    var totalDistance: Double? = 0.0
    var totalTime: Double? = 0.0
    var averagePace: Double? = 0.0
    
    
}

extension User{
    static var MOCK_USERS: [User] = [
        .init(id: NSUUID().uuidString, username: "Spiderman", profileImageUrl: "spiderman", fullname: "Spiderman", bio: "Spiderman Bio", email: "spiderman@gmail.com"),
        .init(id: NSUUID().uuidString, username: "Venom", profileImageUrl: "venom-2", fullname: "Venom Full", bio: "Vennom bio", email: "venom@gmail.com"),
        .init(id: NSUUID().uuidString, username: "ironman", profileImageUrl: "iron-man-1", fullname: "Iron Man", bio: "Iron Man Bio", email: "ironman@gmail.com"),
        .init(id: NSUUID().uuidString, username: "blackpanther", profileImageUrl: "black-panther-1", fullname: "Black Panther", bio: "Black Panther Bio", email: "blackpanther@gmail.com"),
        
    ]
}

extension LeaderUser {
    static var MOCK_LEADER_USERS: [LeaderUser] = User.MOCK_USERS.map { user in
        LeaderUser(
            id: user.id,
            name: user.username,
            totalDistance: Double.random(in: 5000...15000), // Random distance for testing
            imageUrl: user.profileImageUrl ?? "https://example.com/default-profile.jpg"
        )
    }
}
