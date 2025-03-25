//
//  RunView.swift
//  Runr
//
//  Created by Noah Moran on 7/1/2025.
//

import SwiftUI
import MapKit
import Firebase
import ActivityKit



// All this below is the map and location logic for the running
class RunTracker: NSObject, ObservableObject {
    @Published var region = MKCoordinateRegion(center: .init(latitude: 40.7128, longitude: -74.0060), span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @Published var isRunning = false
    @Published var presentCountdown = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var distanceTraveled: Double = 0
    @Published var speed: Double = 0 // speed in metres per second
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var paceString: String = "0:00 / km"



    
    // Location Tracking
    private var locationManager: CLLocationManager?
    private var startLocation: CLLocation?
    private var lastLocation: CLLocation?
    private var timer: Timer?
    
    override init(){
        super.init()
        
        Task {
            await MainActor.run{
                locationManager = CLLocationManager()
                locationManager?.delegate = self
                locationManager?.requestWhenInUseAuthorization()
                locationManager?.requestLocation() // Ask for the current location immediately
            }
        }
    }
    
    // Function to start running
    func startRun(){
        isRunning = true
        startLocation = nil
        distanceTraveled = 0
        elapsedTime = 0
        
        locationManager?.startUpdatingLocation()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.elapsedTime += 1
                self.updatePace()
            }
        }

    }
    
    // Function to stop a run
    func stopRun() {
        isRunning = false
        locationManager?.stopUpdatingLocation()
        timer?.invalidate()
        print("Route Coordinates: \(routeCoordinates)") // Check if coordinates were collected
    }
    
    // Function to pause a run (but doesn't wipe the current running data)
    func pauseRun() {
            // Stop location updates and invalidate timer without resetting stats
            locationManager?.stopUpdatingLocation()
            timer?.invalidate()
            timer = nil
            isRunning = false
        }

    // Function to resume a run (after pausing it)
    func resumeRun() {
            // Resume location updates and restart timer
            locationManager?.startUpdatingLocation()
            // Restart timer without resetting stats
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.elapsedTime += 1
                // update paceString accordingly
            }
            isRunning = true
        }

    
    // Uploading the run data to google firebase database
    func uploadRunData(withCaption caption: String, footwear: String) async {
        guard let userId = AuthService.shared.userSession?.uid else {
            print("DEBUG: No user logged in.")
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        do {
            // Fetch username from Firestore
            let userSnapshot = try await userRef.getDocument()
            guard let username = userSnapshot.data()?["username"] as? String else {
                print("DEBUG: Username not found for userId \(userId)")
                return
            }

            // Generate a custom run ID using the timestamp
            let timestamp = Date().formatted(date: .numeric, time: .standard)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: " ", with: "_")
            let runId = "\(username)_\(timestamp)"
            let runRef = userRef.collection("runs").document(runId)

            // Include the footwear field in the run data
            let runData: [String: Any] = [
                "date": Timestamp(date: Date()),
                "distance": self.distanceTraveled,
                "elapsedTime": self.elapsedTime,
                "routeCoordinates": self.routeCoordinates.map { ["latitude": $0.latitude, "longitude": $0.longitude] },
                "caption": caption,
                "footwear": footwear
            ]

            // Save the run data
            try await runRef.setData(runData)
            print("DEBUG: Run data uploaded with custom ID: \(runId)")

            // Update total stats and footwearStats in Firestore using a transaction
            try await db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    let userSnapshot = try transaction.getDocument(userRef)
                    
                    var currentTotalDistance = userSnapshot.data()?["totalDistance"] as? Double ?? 0
                    var currentTotalTime = userSnapshot.data()?["totalTime"] as? Double ?? 0

                    let newTotalDistance = currentTotalDistance + (self.distanceTraveled / 1000) // Convert meters to km
                    let newTotalTime = currentTotalTime + self.elapsedTime
                    let newAveragePace = newTotalDistance > 0 ? (newTotalTime) / newTotalDistance : 0.0

                    // Update footwearStats dictionary
                    var currentFootwearStats = userSnapshot.data()?["footwearStats"] as? [String: Double] ?? [:]
                    let currentFootwearMileage = currentFootwearStats[footwear] ?? 0.0
                    currentFootwearStats[footwear] = currentFootwearMileage + (self.distanceTraveled / 1000)
                    
                    transaction.updateData([
                        "totalDistance": newTotalDistance,
                        "totalTime": newTotalTime,
                        "averagePace": newAveragePace,
                        "footwearStats": currentFootwearStats
                    ], forDocument: userRef)
                    
                    print("DEBUG: Firestore transaction committed successfully.")
                    return nil
                } catch {
                    print("Transaction failed: \(error.localizedDescription)")
                    errorPointer?.pointee = NSError(domain: "FirestoreTransaction", code: -1, userInfo: nil)
                    return nil
                }
            })

            // Save a reference to the run in the "posts" collection
            let postRef = db.collection("posts").document(runId)
            let postData: [String: Any] = [
                "id": runId,
                "ownerUid": userId,
                "username": username,
                "runId": runId,
                "likes": 0,
                "caption": caption,
                "timestamp": Timestamp(date: Date())
            ]
            try await postRef.setData(postData)
            print("DEBUG: Run data uploaded with ID: \(runId) and referenced in posts.")

        } catch {
            print("DEBUG: Failed to upload run data with error \(error.localizedDescription)")
        }
    }













    // Displaying a history of runs for a user
    func fetchRuns() async -> [RunData] {
        guard let userId = AuthService.shared.userSession?.uid else { return [] }
        
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(userId).collection("runs").getDocuments()
            let runs = snapshot.documents.compactMap { document -> RunData? in
                let data = document.data()
                guard
                    let date = data["date"] as? Timestamp,
                    let distance = data["distance"] as? Double,
                    let elapsedTime = data["elapsedTime"] as? Double,
                    let coordinates = data["routeCoordinates"] as? [[String: Double]]
                else { return nil }
                
                let route = coordinates.map { CLLocationCoordinate2D(latitude: $0["latitude"] ?? 0, longitude: $0["longitude"] ?? 0) }

                return RunData(
                    date: date.dateValue(),
                    distance: distance,
                    elapsedTime: elapsedTime,
                    routeCoordinates: route
                )

            }
            return runs
        } catch {
            print("DEBUG: Failed to fetch runs with error \(error.localizedDescription)")
            return []
        }
    }


    
    
    // Update the speed
    func updatePace() {
        guard distanceTraveled > 0 else {
            DispatchQueue.main.async {
                self.paceString = "0:00 / km"
            }
            return
        }

        let paceInSecondsPerKm = elapsedTime / (distanceTraveled / 1000)
        let paceMinutes = Int(round(paceInSecondsPerKm / 60))
        let paceSeconds = Int(round(paceInSecondsPerKm)) % 60

        DispatchQueue.main.async {
            self.paceString = String(format: "%d:%02d / km", paceMinutes, paceSeconds)
        }
    }



    
    
    // Drawing a route and adding pins


    
}

// Extension to the class "RunTracker"
// MARK: Location Tracking

extension RunTracker: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            
            // If you don't want to record anything while paused:
            // Only update 'lastLocation', 'distanceTraveled', and 'routeCoordinates' if isRunning is true
            if isRunning {
                if startLocation == nil {
                    startLocation = location
                }
                
                if let last = lastLocation {
                    let distance = location.distance(from: last)
                    distanceTraveled += distance
                }
                
                routeCoordinates.append(location.coordinate)
                lastLocation = location
            } else {
                // If paused, reset lastLocation to the most recent location so
                // you don’t get a big jump when resuming.
                // This ensures that when you resume, the next distance calculation
                // starts from the current position (not the old paused position).
                lastLocation = location
            }

            // You can still update the map center to show the user's current position,
            // even if isRunning is false.
            DispatchQueue.main.async { [weak self] in
                self?.region.center = location.coordinate
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("locationManager didFailWithError: \(error.localizedDescription)")
        }
    }



struct AreaMap: View {
    @Binding var region: MKCoordinateRegion
    var body: some View {
        let binding = Binding(
            get: { self.region },
            set: { newValue in
                DispatchQueue.main.async {
                    self.region = newValue
                }
            }
        )
        return Map(coordinateRegion: binding, showsUserLocation: true)
            .ignoresSafeArea()
    }
}

// This is for my live activities where i can create real-time notifictaions for the user
func startLiveActivity() {
    if #available(iOS 16.1, *) {
        let initialState = RunningActivityAttributes.ContentState(distance: 0, pace: 0, elapsedTime: 0)
        let attributes = RunningActivityAttributes()

        do {
            let activity = try Activity<RunningActivityAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            print("Live Activity started with id: \(activity.id)")
        } catch {
            print("Error starting live activity: \(error)")
        }
    }
}

