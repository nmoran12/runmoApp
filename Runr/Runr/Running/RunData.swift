//
//  RunStruct.swift
//  Runr
//
//  Created by Noah Moran on 13/3/2025.
//

import Foundation
import CoreLocation

extension RunData {
    var startDate: Date {
        return date
    }
    
    var endDate: Date {
        return date.addingTimeInterval(elapsedTime)
    }
}


struct CoordinateWrapper: Codable {
    let latitude: Double
    let longitude: Double
}

struct RunData: Identifiable, Codable {
    var id = UUID().uuidString
    let date: Date
    let distance: Double
    let elapsedTime: Double
    let routeCoordinates: [CLLocationCoordinate2D]
    
    init(date: Date, distance: Double, elapsedTime: Double, routeCoordinates: [CLLocationCoordinate2D]) {
         self.date = date
         self.distance = distance
         self.elapsedTime = elapsedTime
         self.routeCoordinates = routeCoordinates
     }
    
    enum CodingKeys: String, CodingKey {
        case date, distance, elapsedTime, routeCoordinates
    }
    
    // Updated decoding to ignore extra keys (like "timestamp")
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        distance = try container.decode(Double.self, forKey: .distance)
        elapsedTime = try container.decode(Double.self, forKey: .elapsedTime)
        
        // Decode as an array of CoordinateWrapper, which only cares about latitude and longitude.
        let coordinates = try container.decode([CoordinateWrapper].self, forKey: .routeCoordinates)
        routeCoordinates = coordinates.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    // Optionally, update encoding to only save latitude and longitude (ignoring timestamp)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(distance, forKey: .distance)
        try container.encode(elapsedTime, forKey: .elapsedTime)
        
        // Only encode latitude and longitude
        let coordinates = routeCoordinates.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
        try container.encode(coordinates, forKey: .routeCoordinates)
    }
}

