//
//  ExploreFeedItem.swift
//  Runr
//
//  Created by Noah Moran on 19/2/2025.
//

import Foundation

struct ExploreFeedItem: Identifiable {
    let exploreFeedId: String // 🔹 Renamed from `id`
    let title: String
    let content: String
    let category: String
    let imageUrl: String
    
    var id: String { exploreFeedId } // 🔹 Keeps Identifiable conformance
}
