//
//  RunStruct.swift
//  Runr
//
//  Created by Noah Moran on 13/3/2025.
//

import Foundation
import CoreLocation

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

    
    // Custom encoding and decoding for CLLocationCoordinate2D
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        distance = try container.decode(Double.self, forKey: .distance)
        elapsedTime = try container.decode(Double.self, forKey: .elapsedTime)

        let coordinates = try container.decode([[String: Double]].self, forKey: .routeCoordinates)
        routeCoordinates = coordinates.map { CLLocationCoordinate2D(latitude: $0["latitude"] ?? 0, longitude: $0["longitude"] ?? 0) }
    }

    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(distance, forKey: .distance)
        try container.encode(elapsedTime, forKey: .elapsedTime)
        
        let coordinates = routeCoordinates.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
        try container.encode(coordinates, forKey: .routeCoordinates)
    }

}
