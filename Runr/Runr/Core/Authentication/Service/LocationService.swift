//
//  LocationService.swift
//  Runr
//
//  Created by Noah Moran on 1/4/2025.
//

import Foundation
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()
    
    private let manager = CLLocationManager()
    
    private override init() {
        super.init()
        manager.delegate = self
    }
    
    /// Ask the user for permission to access their location
    func requestLocationPermissions() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// Fetch the user's location once, then reverse-geocode it and store in Firestore
    func fetchAndStoreUserLocation() {
        manager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Stop updating once we have a location
        manager.stopUpdatingLocation()
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("DEBUG: Reverse geocode error: \(error.localizedDescription)")
                return
            }
            guard let placemark = placemarks?.first else { return }
            
            // Prefer subAdministrativeArea; if not available and in SA, default to "Adelaide"
            let city: String = {
                if let subAdmin = placemark.subAdministrativeArea, !subAdmin.isEmpty {
                    return subAdmin
                } else if let locality = placemark.locality, !locality.isEmpty {
                    if placemark.administrativeArea == "SA" {
                        return "Adelaide"
                    }
                    return locality
                } else {
                    return "Unknown City"
                }
            }()
            
            print("DEBUG: Reverse geocoded city: \(city)")
            let country = placemark.country ?? "Unknown Country"
            let isoCode = placemark.isoCountryCode ?? "Unknown"
            
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            
            db.collection("users")
                .document(userId)
                .updateData([
                    "city": city,
                    "country": country,
                    "isoCountryCode": isoCode
                ]) { error in
                    if let error = error {
                        print("DEBUG: Failed to update user location: \(error.localizedDescription)")
                    } else {
                        print("DEBUG: User location updated to: \(city), \(country) (\(isoCode))")
                    }
                }
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("DEBUG: Failed to get user location: \(error.localizedDescription)")
    }
}
