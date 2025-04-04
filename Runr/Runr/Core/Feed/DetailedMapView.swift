//
//  DetailedMapView.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI
import MapKit

// Custom MKPolyline subclass to hold a stroke color
class PacePolyline: MKPolyline {
    var strokeColor: UIColor?
}

struct DetailedMapView: UIViewRepresentable {
    var timedLocations: [TimedLocation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove existing overlays to avoid stacking
        mapView.removeOverlays(mapView.overlays)
        guard timedLocations.count > 1 else { return }
        
        // Compute overall total distance
        var totalDistance: Double = 0.0
        for i in 1..<timedLocations.count {
            let prev = timedLocations[i - 1]
            let curr = timedLocations[i]
            let segmentDistance = CLLocation(latitude: prev.coordinate.latitude,
                                             longitude: prev.coordinate.longitude)
                .distance(from: CLLocation(latitude: curr.coordinate.latitude,
                                           longitude: curr.coordinate.longitude))
            totalDistance += segmentDistance
        }
        
        // Total time from first to last point
        let totalTime = timedLocations.last!.timestamp.timeIntervalSince(timedLocations.first!.timestamp)
        guard totalDistance > 0 else { return }
        
        // Average pace in seconds per km
        let averagePace = totalTime / (totalDistance / 1000)
        
        // Define thresholds: 10 sec/km faster is "good", 10 sec/km slower is "bad"
        let goodThreshold = averagePace - 10
        let badThreshold = averagePace + 10
        
        // First, compute the instantaneous pace for each segment
        var paces: [Double] = [] // seconds per km for each segment
        for i in 1..<timedLocations.count {
            let prev = timedLocations[i - 1]
            let curr = timedLocations[i]
            let segmentDistance = CLLocation(latitude: prev.coordinate.latitude,
                                             longitude: prev.coordinate.longitude)
                .distance(from: CLLocation(latitude: curr.coordinate.latitude,
                                           longitude: curr.coordinate.longitude))
            let segmentTime = curr.timestamp.timeIntervalSince(prev.timestamp)
            if segmentDistance > 0 {
                let pace = segmentTime / (segmentDistance / 1000)
                paces.append(pace)
            } else {
                paces.append(averagePace) // fallback to average if distance is zero
            }
        }
        
        // Smooth the pace values using a moving average filter (window size = 3)
        var smoothedPaces: [Double] = []
        for i in 0..<paces.count {
            var sum = paces[i]
            var count = 1.0
            if i - 1 >= 0 {
                sum += paces[i - 1]
                count += 1.0
            }
            if i + 1 < paces.count {
                sum += paces[i + 1]
                count += 1.0
            }
            smoothedPaces.append(sum / count)
        }
        
        // Now, for each segment, use the smoothed pace value to determine the color.
        for i in 1..<timedLocations.count {
            let prev = timedLocations[i - 1]
            let curr = timedLocations[i]
            
            // Get the smoothed pace for this segment (corresponds to index i-1)
            let segmentPace = smoothedPaces[i - 1]
            
            // Calculate interpolation fraction (0 = good = green, 1 = bad = red)
            var fraction: CGFloat = 0.0
            if segmentPace <= goodThreshold {
                fraction = 0.0
            } else if segmentPace >= badThreshold {
                fraction = 1.0
            } else {
                fraction = CGFloat((segmentPace - goodThreshold) / (badThreshold - goodThreshold))
            }
            // Interpolate between green and red
            let color = UIColor(red: fraction, green: 1.0 - fraction, blue: 0.0, alpha: 1.0)
            
            // Create a polyline for this segment
            var coordinates = [prev.coordinate, curr.coordinate]
            let polyline = PacePolyline(coordinates: &coordinates, count: coordinates.count)
            polyline.strokeColor = color
            mapView.addOverlay(polyline)
        }
        
        // Set map region to encompass the entire run with padding
        let latitudes = timedLocations.map { $0.coordinate.latitude }
        let longitudes = timedLocations.map { $0.coordinate.longitude }
        if let minLat = latitudes.min(),
           let maxLat = latitudes.max(),
           let minLon = longitudes.min(),
           let maxLon = longitudes.max() {
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat) * 1.5,
                longitudeDelta: (maxLon - minLon) * 1.5
            )
            
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let pacePolyline = overlay as? PacePolyline {
                let renderer = MKPolylineRenderer(polyline: pacePolyline)
                renderer.strokeColor = pacePolyline.strokeColor ?? .blue
                renderer.lineWidth = 5    // Increased line width for better visibility
                renderer.lineCap = .round // Rounded caps for smoother lines
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

#Preview {
    let sampleLocations = [
        TimedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            timestamp: Date(),
            altitude: 50.0  // Simulated altitude in meters
        ),
        TimedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            timestamp: Date().addingTimeInterval(60),
            altitude: 55.0  // Simulated altitude in meters
        ),
        TimedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4196),
            timestamp: Date().addingTimeInterval(120),
            altitude: 53.0  // Simulated altitude in meters
        )
    ]
    return DetailedMapView(timedLocations: sampleLocations)
}

