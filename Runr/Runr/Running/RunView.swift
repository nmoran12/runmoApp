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
import FirebaseAuth





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
    @Published var timedLocations: [TimedLocation] = []
    private weak var ghostRunnerManager: GhostRunnerManager?


    // New flag to ensure we update the user's location only once (or when desired)
    @Published var hasUpdatedUserLocation: Bool = false

    
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
    
    // --- NEW: Method to set the manager ---
        func setGhostRunnerManager(_ manager: GhostRunnerManager) {
            self.ghostRunnerManager = manager
        }
    
    // Function to start running
    func startRun() {
        isRunning = true
        
        // Reset everything to zero or nil
        startLocation = nil
        lastLocation = nil
        distanceTraveled = 0
        elapsedTime = 0
        routeCoordinates.removeAll()
        timedLocations.removeAll()
        paceString = "0:00 / km"
        
        // --- Reset ghosts when starting a new run ---
                ghostRunnerManager?.resetForNewRun()
        
        locationManager?.startUpdatingLocation()
        
        // --- Modify Timer ---
                timer?.invalidate() // Invalidate existing timer just in case
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return } // Use weak self pattern
                    DispatchQueue.main.async {
                        self.elapsedTime += 1
                        self.updatePace()
                        // !!! --- ADD THIS LINE --- !!!
                        // --- DEBUGGING ---
                                if self.ghostRunnerManager == nil {
                                    print("!!! DEBUG: RunTracker Timer (Start) - ghostRunnerManager is NIL !!!")
                                } else {
                                    // print("DEBUG: RunTracker Timer (Start) - Calling update for elapsedTime: \(self.elapsedTime)") // Optional: uncomment if needed
                                    self.ghostRunnerManager?.updateSelectedGhostRunnerPositions(elapsedTime: self.elapsedTime)
                                }
                                // --- END DEBUGGING ---
                    }
                }
            }
    
    

    
    // Function to stop a run
    func stopRun() {
        isRunning = false
        locationManager?.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil // Clear timer reference
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
            timer?.invalidate() // Invalidate existing timer just in case
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
             guard let self = self else { return }
             DispatchQueue.main.async {
                 self.elapsedTime += 1
                 self.updatePace()
                 // --- DEBUGGING ---
                 if self.ghostRunnerManager == nil {
                     print("!!! DEBUG: RunTracker Timer (Resume) - ghostRunnerManager is NIL !!!")
                 } else {
                     // print("DEBUG: RunTracker Timer (Resume) - Calling update for elapsedTime: \(self.elapsedTime)") // Optional: uncomment if needed
                     self.ghostRunnerManager?.updateSelectedGhostRunnerPositions(elapsedTime: self.elapsedTime)
                 }
                 // --- END DEBUGGING ---
             }
        }
            isRunning = true
        }

    
    // Uploading the run data to google firebase database
    // --- MODIFIED: uploadRunData Function ---
        func uploadRunData(withCaption caption: String, footwear: String) async {
            guard let userId = AuthService.shared.userSession?.uid else {
                print("UPLOAD ERROR: No user logged in.")
                return
            }
            // Ensure there's actually data to upload
            guard distanceTraveled > 0 || elapsedTime > 0 else {
                 print("UPLOAD WARNING: No distance or time recorded. Skipping upload.")
                 return
             }

            let db = Firestore.firestore()
            let userRef = db.collection("users").document(userId)
            let runCompletionDate = Date() // Capture completion date

            do {
                // 1. Fetch username (already have this logic)
                let userSnapshot = try await userRef.getDocument()
                guard let username = userSnapshot.data()?["username"] as? String else {
                    print("UPLOAD ERROR: Username not found for userId \(userId)")
                    return
                }

                // 2. Generate Run ID (already have this logic)
                let timestampString = runCompletionDate.formatted(date: .numeric, time: .standard)
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: ":", with: "-")
                    .replacingOccurrences(of: " ", with: "_")
                let runId = "\(username)_\(timestampString)_\(UUID().uuidString.prefix(4))" // Add UUID snippet for uniqueness
                let runRef = userRef.collection("runs").document(runId)

                // 3. Prepare Run Data Dictionary
                let runDataForUpload: [String: Any] = [
                    "date": Timestamp(date: runCompletionDate), // Use completion date
                    "distance": self.distanceTraveled, // Store distance in METERS
                    "elapsedTime": self.elapsedTime, // Store time in SECONDS
                     // Map TimedLocation structs correctly
                    "routeCoordinates": self.timedLocations.map { timedLoc in
                        [
                            "latitude": timedLoc.coordinate.latitude,
                            "longitude": timedLoc.coordinate.longitude,
                            "timestamp": Timestamp(date: timedLoc.timestamp), // Store timestamp
                            "altitude": timedLoc.altitude // Store altitude
                        ]
                    },
                    "caption": caption,
                    "footwear": footwear
                ]

                // 4. Save the Run Data
                try await runRef.setData(runDataForUpload)
                print("DEBUG: Run data uploaded successfully with Run ID: \(runId)")

                // 5. Update User Aggregate Stats (Transaction)
                // Make sure to handle the footwear string correctly if it might be empty
                let validFootwear = footwear.isEmpty ? "Unknown" : footwear
                try await db.runTransaction({ (transaction, errorPointer) -> Any? in
                    do {
                        let userDoc = try transaction.getDocument(userRef)

                        // Fetch current stats
                        let currentTotalDistanceKm = userDoc.data()?["totalDistance"] as? Double ?? 0
                        let currentTotalTimeSec = userDoc.data()?["totalTime"] as? Double ?? 0
                        var currentFootwearStats = userDoc.data()?["footwearStats"] as? [String: Double] ?? [:]

                        // Calculate new stats
                        let runDistanceKm = self.distanceTraveled / 1000.0 // Convert to KM for aggregate stats
                        let newTotalDistanceKm = currentTotalDistanceKm + runDistanceKm
                        let newTotalTimeSec = currentTotalTimeSec + self.elapsedTime
                        // Recalculate average pace if needed (Pace in seconds per KM)
                        let newAveragePaceSecPerKm = newTotalDistanceKm > 0 ? (newTotalTimeSec / newTotalDistanceKm) : 0.0

                        // Update footwear stats (using KM)
                        let currentFootwearMileageKm = currentFootwearStats[validFootwear] ?? 0.0
                        currentFootwearStats[validFootwear] = currentFootwearMileageKm + runDistanceKm

                        // Update user document in the transaction
                        transaction.updateData([
                            "totalDistance": newTotalDistanceKm,     // Store aggregate distance in KM
                            "totalTime": newTotalTimeSec,         // Store aggregate time in Seconds
                            "averagePace": newAveragePaceSecPerKm, // Store aggregate pace in Sec/KM
                            "footwearStats": currentFootwearStats   // Update footwear stats
                        ], forDocument: userRef)

                        print("DEBUG: Firestore user stats transaction committed successfully.")
                        return nil // Success
                    } catch let fetchError as NSError {
                        print("TRANSACTION ERROR: \(fetchError.localizedDescription)")
                        errorPointer?.pointee = fetchError
                        return nil // Failure
                    }
                })

                // 6. Create Feed Post (if applicable)
                let postRef = db.collection("posts").document(runId) // Use runId for post ID for easy linking
                let postData: [String: Any] = [
                    "id": runId, // Post ID matches Run ID
                    "ownerUid": userId,
                    "username": username, // Denormalize username
                    "runId": runId, // Reference to the run document
                    "likes": 0,
                    "caption": caption,
                    "timestamp": Timestamp(date: runCompletionDate), // Use completion date
                    // Add other relevant post fields: runDistance, runTime, etc. for feed display
                     "runDistance": self.distanceTraveled, // Store meters in post too? Or km? Be consistent.
                     "runElapsedTime": self.elapsedTime
                ]
                try await postRef.setData(postData)
                print("DEBUG: Feed post created successfully for Run ID: \(runId)")

                // --- !!! 7. UPDATE GOALS PROGRESS !!! ---
                print("DEBUG: Attempting to update goals progress...")
                await GoalsService.shared.updateGoalsProgress(
                    runDistance: self.distanceTraveled, // Pass distance in METERS
                    runDuration: self.elapsedTime, // Pass duration in SECONDS
                    runDate: runCompletionDate // Pass the date the run was completed
                )
                print("DEBUG: Goal progress update process finished.")
                // --- !!! END GOALS UPDATE !!! ---


            } catch {
                // Consolidated error handling
                print("UPLOAD ERROR: Failed during run upload/update process: \(error.localizedDescription)")
                // Optionally: Implement retry logic or user feedback
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
             guard distanceTraveled > 10 else { // Only calculate pace after a small distance (e.g., 10 meters)
                 DispatchQueue.main.async {
                     self.paceString = "0:00 / km"
                 }
                 return
             }

             let distanceKm = distanceTraveled / 1000.0 // Ensure floating point division
             guard distanceKm > 0, elapsedTime > 0 else { return } // Avoid division by zero

             let paceInSecondsPerKm = elapsedTime / distanceKm // Pace calculation

             let paceMinutes = Int(paceInSecondsPerKm / 60) // Integer part for minutes
             let paceSeconds = Int(paceInSecondsPerKm) % 60 // Remainder for seconds

             DispatchQueue.main.async {
                 self.paceString = String(format: "%d:%02d / km", paceMinutes, paceSeconds)
             }
         }
    
    // MARK: - New Function to Update User Location in Firestore
        private func updateUserLocation(with location: CLLocation) {
            // Reverse geocode the provided location
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    print("DEBUG: Reverse geocode error: \(error.localizedDescription)")
                    return
                }
                guard let placemark = placemarks?.first else { return }
                
                let city = placemark.locality ?? "Unknown City"
                let country = placemark.country ?? "Unknown Country"
                let isoCode = placemark.isoCountryCode ?? "Unknown"
                
                guard let userId = Auth.auth().currentUser?.uid else { return }
                let db = Firestore.firestore()
                
                db.collection("users").document(userId).updateData([
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
}

// Extension to the class "RunTracker"
// MARK: Location Tracking

extension RunTracker: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Check location accuracy - ignore inaccurate points if needed
          guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 else { // Example: Ignore if accuracy is worse than 50m
              print("DEBUG: Ignoring inaccurate location point. Accuracy: \(location.horizontalAccuracy)")
              return
          }

        
        if isRunning {
            if startLocation == nil {
                startLocation = location
            }
            
            if let last = lastLocation {
                              // Filter out points that are too close in time or distance to avoid jitter
                              guard location.timestamp.timeIntervalSince(last.timestamp) > 0.5 else { return } // At least 0.5 sec passed
                              let distance = location.distance(from: last)
                              guard distance > 1.0 else { return } // At least 1 meter moved

                             distanceTraveled += distance
                         }
            
            timedLocations.append(TimedLocation(coordinate: location.coordinate, timestamp: location.timestamp, altitude: location.altitude))
            lastLocation = location
        } else {
            lastLocation = location
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.region.center = location.coordinate
        }
        
        // NEW: Update user's location data once using the current location (if not already updated)
        if !hasUpdatedUserLocation {
            updateUserLocation(with: location)
            hasUpdatedUserLocation = true
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

