//
//  Post.swift
//  InstagramTutorial
//
//  Created by Noah Moran on 3/1/2025.
//

import Foundation

struct Post: Identifiable, Hashable, Codable {
    let id: String
    let ownerUid: String
    let caption: String
    var likes: Int
    let imageUrl: String
    let timestamp: Date
    let user: User
    var runData: RunData?

    // Custom initializer
    init(id: String, ownerUid: String, caption: String, likes: Int, imageUrl: String, timestamp: Date, user: User, runData: RunData?) {
        self.id = id
        self.ownerUid = ownerUid
        self.caption = caption
        self.likes = likes
        self.imageUrl = imageUrl
        self.timestamp = timestamp
        self.user = user
        self.runData = runData
    }
}


extension Post{
    static var MOCK_POSTS: [Post] = [
        .init(
            id: NSUUID().uuidString,
            ownerUid: NSUUID().uuidString,
            caption: "This is some test caption for now",
            likes: 123,
            imageUrl: "spiderman",
            timestamp: Date(),
            user: User.MOCK_USERS[0],
            runData: RunData(date: Date(), distance: 5.0, elapsedTime: 30.0, routeCoordinates: [])
        ),
        
        .init(
            id: NSUUID().uuidString,
            ownerUid: NSUUID().uuidString,
            caption: "Wakanda Forever",
            likes: 104,
            imageUrl: "black-panther-1",
            timestamp: Date(),
            user: User.MOCK_USERS[3],
            runData: RunData(date: Date(), distance: 5.0, elapsedTime: 30.0, routeCoordinates: [])
        ),
        
        .init(
            id: NSUUID().uuidString,
            ownerUid: NSUUID().uuidString,
            caption: "This is some test caption for now for ironman",
            likes: 231,
            imageUrl: "iron-man-1",
            timestamp: Date(),
            user: User.MOCK_USERS[2],
            runData: RunData(date: Date(), distance: 5.0, elapsedTime: 30.0, routeCoordinates: [])
        ),
        
        .init(
            id: NSUUID().uuidString,
            ownerUid: NSUUID().uuidString,
            caption: "Venom Caption for now",
            likes: 567,
            imageUrl: "venom-1",
            timestamp: Date(),
            user: User.MOCK_USERS[1],
            runData: RunData(date: Date(), distance: 5.0, elapsedTime: 30.0, routeCoordinates: [])
        ),
        
        .init(
            id: NSUUID().uuidString,
            ownerUid: NSUUID().uuidString,
            caption: "Venom 2 Caption for now",
            likes: 567,
            imageUrl: "venom-2",
            timestamp: Date(),
            user: User.MOCK_USERS[1],
            runData: RunData(date: Date(), distance: 5.0, elapsedTime: 30.0, routeCoordinates: [])
        )
    ]
}

extension RunData: Equatable {
    static func == (lhs: RunData, rhs: RunData) -> Bool {
        return lhs.id == rhs.id &&
               lhs.date == rhs.date &&
               lhs.distance == rhs.distance &&
               lhs.elapsedTime == rhs.elapsedTime
    }
}

extension RunData: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
        hasher.combine(distance)
        hasher.combine(elapsedTime)
    }
}
