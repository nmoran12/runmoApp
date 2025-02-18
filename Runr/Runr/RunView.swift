//
//  RunView.swift
//  Runr
//
//  Created by Noah Moran on 7/1/2025.
//

import SwiftUI
import MapKit
import Firebase


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
    
    // Uploading the run data to google firebase database
    func uploadRunData() async {
        guard let userId = AuthService.shared.userSession?.uid else {
            print("DEBUG: No user logged in.")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        let runData: [String: Any] = [
            "date": Timestamp(date: Date()),
            "distance": distanceTraveled,
            "elapsedTime": elapsedTime,
            "routeCoordinates": routeCoordinates.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
        ]
        
        do {
            // Add the new run data
            try await userRef.collection("runs").addDocument(data: runData)
            
            // Update the total distance, total time, and average pace in a transaction
            try await db.runTransaction { transaction -> Any? in
                do {
                    let userSnapshot = try transaction.getDocument(userRef)
                    
                    // Get the current total distance and time, or default to 0 if not present
                    let currentTotalDistance = userSnapshot.data()?["totalDistance"] as? Double ?? 0
                    let currentTotalTime = userSnapshot.data()?["totalTime"] as? Double ?? 0
                    
                    // Calculate the new total distance and time
                    let newTotalDistance = currentTotalDistance + self.distanceTraveled
                    let newTotalTime = currentTotalTime + Double(self.elapsedTime) / 3600 // Convert seconds to hours
                    
                    // Calculate the new average pace (hours per km)
                    let newAveragePace = (newTotalTime * 60) / newTotalDistance

                    
                    // Update Firestore with the new totals
                    transaction.updateData([
                        "totalDistance": newTotalDistance,
                        "totalTime": newTotalTime,
                        "averagePace": newAveragePace
                    ], forDocument: userRef)
                } catch {
                    print("DEBUG: Error during transaction: \(error.localizedDescription)")
                    throw error
                }
                return nil
            }
            
            print("DEBUG: Run data uploaded and totals updated successfully.")
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
                return RunData(date: date.dateValue(), distance: distance, elapsedTime: elapsedTime, routeCoordinates: route)
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
        
        if startLocation == nil {
            startLocation = location
        }
        
        if let last = lastLocation {
            let distance = location.distance(from: last) // Distance in meters
            distanceTraveled += distance
        }
        
        routeCoordinates.append(location.coordinate)
        lastLocation = location
        
        DispatchQueue.main.async { [weak self] in
            self?.region.center = location.coordinate
        }
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



// This is for the visual aspect of the running tab, where you have the map and the start button
struct RunView: View {
    @StateObject var runTracker = RunTracker()
    @State private var isPressed = false
    @State private var isImagePressed = false
    @State private var showRunInfo = false

    
    
    
    
    var body: some View {
        
        NavigationStack {
                ZStack {
                    // Map Layer
                    AreaMap(region: $runTracker.region)
                        .edgesIgnoringSafeArea(.all) // Ensures the map fills the entire screen

                    // Overlay Layer (Text and Image)
                    VStack {
                        HStack {
                            //Text("Runr")
                            //    .font(.largeTitle)
                            //    .bold()
                             //   .foregroundColor(.black)
                            
                            Spacer()
                            
                            
                            if runTracker.isRunning == false{
                                // button to select footwear
                                FootwearButtonView()
                            }
                        }
                        .padding()
                        Spacer()
                        
                        // Display Running Information while the runner is running
                        
                        if runTracker.isRunning {
                         
                            VStack(spacing: 10){
                                HStack{
                                    VStack(alignment: .leading){
                                        Text("Distance")
                                            .foregroundColor(.black)
                                            .fontWeight(.semibold)
                                        Text("\(runTracker.distanceTraveled / 1000, specifier: "%.2f") km")
                                            .foregroundColor(.black)
                                    }
                                    .padding(20)
                                    .background(.white)
                                    .cornerRadius(10)
                                    
                                    VStack(alignment: .leading){
                                        Text("Time")
                                            .foregroundColor(.black)
                                            .fontWeight(.semibold)
                                        Text("\(Int(runTracker.elapsedTime) / 60) min \(Int(runTracker.elapsedTime) % 60) sec")
                                            .foregroundColor(.black)
                                    }
                                    .padding(20)
                                    .background(.white)
                                    .cornerRadius(10)
                                    
                                    VStack(alignment: .leading){
                                        Text("Pace")
                                            .foregroundColor(.black)
                                            .fontWeight(.semibold)
                                        Text("\(runTracker.paceString)")
                                            .foregroundColor(.black)
                                    }
                                    .padding(20)
                                    .background(.white)
                                    .cornerRadius(10)
                        }

                                Spacer()
                            }
                        }
                        
                    }

                    // Start Button at the bottom
                    NavigationLink(
                        destination: RunInfoDisplayView(routeCoordinates: runTracker.routeCoordinates)
                            .environmentObject(runTracker),
                        isActive: $showRunInfo
                    ) {
                        EmptyView()
                    }

                    
                    
                    
                    VStack {
                        Spacer()
                        // Start/Stop Button
                        Button {
                            if runTracker.isRunning {
                                runTracker.stopRun()
                                print("Stopped run")
                                showRunInfo = true // Trigger navigation
                            } else {
                                runTracker.startRun()
                                print("Start run")
                            }
                        } label: {
                            Text(runTracker.isRunning ? "Stop" : "Start")
                                .bold()
                                .font(.title)
                                .foregroundStyle(.black)
                                .padding(36)
                                .background(.white)
                                .clipShape(Circle())
                        }
                        .padding(.bottom, 48)
                            .scaleEffect(isPressed ? 1.1 : 1.0) // Scale effect when pressed
                            .opacity(isPressed ? 0.8 : 1.0)      // Opacity effect when pressed
                            .animation(.easeInOut(duration: 0.2), value: isPressed) // Smooth animation
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in isPressed = true }
                                    .onEnded { _ in isPressed = false }
                                )
                    }
                }
            }
        }
        
    }
