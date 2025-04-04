//
//  SplitsModel.swift
//  Runr
//
//  Created by Noah Moran on 25/3/2025.
//

import Foundation
import CoreLocation

struct TimedLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let altitude: Double  // New property: altitude in meters
}


struct Split {
    let splitNumber: Int
    let distanceMeters: Double
    let splitTime: TimeInterval
    
    var pace: TimeInterval {
        // seconds per km (for a 1 km split)
        return splitTime
    }
    

    
}

struct PaceData: Identifiable {
    let id = UUID()
    let distanceKm: Double
    let paceMinPerKm: Double
}

func computeKilometerSplits(from locations: [TimedLocation]) -> [Split] {
    guard locations.count > 1 else { return [] }
    
    var splits: [Split] = []
    
    var totalDistance: Double = 0.0
    var nextSplitDistance: Double = 1000.0 // 1 km threshold
    var lastSplitTime = locations.first!.timestamp
    var distanceAtLastSplit: Double = 0.0
    var splitIndex = 1
    
    // We need to convert TimedLocation into CLLocation for distance calculations
    let clLocations = locations.map { CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
    
    for i in 1..<clLocations.count {
        let prevLocation = clLocations[i - 1]
        let currLocation = clLocations[i]
        let segmentDistance = currLocation.distance(from: prevLocation)
        totalDistance += segmentDistance
        
        // If we've passed the next km mark in the current segment...
        while totalDistance >= nextSplitDistance {
            // Calculate how far into this segment the split was reached
            let distanceIntoSegment = nextSplitDistance - (totalDistance - segmentDistance)
            let fractionOfSegment = distanceIntoSegment / segmentDistance
            
            // Interpolate the timestamp between the two points
            let timeBetween = locations[i].timestamp.timeIntervalSince(locations[i - 1].timestamp)
            let timeAtSplit = locations[i - 1].timestamp.addingTimeInterval(timeBetween * fractionOfSegment)
            
            let splitDistance = nextSplitDistance - distanceAtLastSplit // ~1000 meters normally
            let splitTime = timeAtSplit.timeIntervalSince(lastSplitTime)
            
            let newSplit = Split(
                splitNumber: splitIndex,
                distanceMeters: splitDistance,
                splitTime: splitTime
            )
            splits.append(newSplit)
            
            // Update for the next split
            lastSplitTime = timeAtSplit
            distanceAtLastSplit = nextSplitDistance
            splitIndex += 1
            nextSplitDistance += 1000.0
        }
    }
    
    // Optionally add a partial split for any leftover distance
    if totalDistance > distanceAtLastSplit {
        let partialDistance = totalDistance - distanceAtLastSplit
        let partialTime = locations.last!.timestamp.timeIntervalSince(lastSplitTime)
        let partialSplit = Split(splitNumber: splitIndex, distanceMeters: partialDistance, splitTime: partialTime)
        splits.append(partialSplit)
    }
    
    return splits
}

func createPaceData(from timedLocations: [TimedLocation]) -> [PaceData] {
    guard timedLocations.count > 1 else { return [] }
    
    var paceDataArray: [PaceData] = []
    var totalDistance: Double = 0.0 // in meters
    let clLocations = timedLocations.map {
        CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
    }
    
    for i in 1..<clLocations.count {
        let distanceSegment = clLocations[i].distance(from: clLocations[i-1])
        totalDistance += distanceSegment
        
        // Time difference in seconds
        let timeDiff = timedLocations[i].timestamp.timeIntervalSince(timedLocations[i-1].timestamp)
        
        // "Instantaneous pace" in sec/km for just this segment:
        // If distanceSegment is zero, skip
        if distanceSegment > 0 {
            let paceSecPerKm = timeDiff / (distanceSegment / 1000.0)
            let paceMinPerKm = paceSecPerKm / 60.0
            
            let distanceKmSoFar = totalDistance / 1000.0
            let paceData = PaceData(distanceKm: distanceKmSoFar, paceMinPerKm: paceMinPerKm)
            paceDataArray.append(paceData)
        }
    }
    
    return paceDataArray
}

