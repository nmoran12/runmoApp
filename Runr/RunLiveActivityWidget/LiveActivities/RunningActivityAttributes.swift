//
//  RunningActivityAttributes.swift
//  Runr
//
//  Created by Noah Moran on 24/3/2025.
//

import Foundation
import ActivityKit

struct RunningActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var distance: Double       // in kilometers or miles
        var pace: Double           // pace in min/km or min/mile
        var elapsedTime: TimeInterval  // running time in seconds
    }
    // You can add any fixed attributes here (e.g., user or session ID)
    
}
