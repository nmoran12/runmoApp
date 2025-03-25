//
//  RouteMapView.swift
//  Runr
//
//  Created by Noah Moran on 10/1/2025.
//

import MapKit
import SwiftUI

struct RouteMapView: UIViewRepresentable {
    var routeCoordinates: [CLLocationCoordinate2D]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        
        // Add the polyline overlay if there are at least 2 coordinates
        if routeCoordinates.count > 1 {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            mapView.addOverlay(polyline)
            
            // Calculate the bounding region for all coordinates
            let latitudes = routeCoordinates.map { $0.latitude }
            let longitudes = routeCoordinates.map { $0.longitude }
            if let minLat = latitudes.min(),
               let maxLat = latitudes.max(),
               let minLon = longitudes.min(),
               let maxLon = longitudes.max() {
                
                let center = CLLocationCoordinate2D(
                    latitude: (minLat + maxLat) / 2,
                    longitude: (minLon + maxLon) / 2
                )
                
                let span = MKCoordinateSpan(
                    latitudeDelta: (maxLat - minLat) * 1.5,  // Add some padding
                    longitudeDelta: (maxLon - minLon) * 1.5
                )
                
                let region = MKCoordinateRegion(center: center, span: span)
                mapView.setRegion(region, animated: true)
            }
        } else if let coordinate = routeCoordinates.first {
            // If there's only one coordinate, show that point with a default span.
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

#Preview {
    RouteMapView(routeCoordinates: [])
}

