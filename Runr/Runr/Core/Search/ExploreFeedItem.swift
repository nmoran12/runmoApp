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

// Helper function to convert ExploreFeedItem to RunningProgram
func convertToRunningProgram(from item: ExploreFeedItem) -> RunningProgram {
    return RunningProgram(
        title: item.title,
        // You can decide how to derive or assign a subtitle – perhaps from item.content or a fixed string.
        subtitle: "Your plan subtitle here",
        imageUrl: item.imageUrl,
        // Here we assume the item's content can be used as the plan overview.
        planOverview: item.content,
        // You might set a default or derive the experience level.
        experienceLevel: "Beginner",
        // Since ExploreFeedItem doesn't include weeklyPlans, you can either supply an empty array or some default values.
        weeklyPlans: []
    )
}
