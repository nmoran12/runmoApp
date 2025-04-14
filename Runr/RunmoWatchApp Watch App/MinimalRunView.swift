//
//  MinimalRunView.swift
//  RunmoWatchApp Watch App
//
//  Created by Noah Moran on 9/4/2025.
//

import SwiftUI
import WatchConnectivity

final class MinimalRunTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var elapsedTime: TimeInterval = 0
    @Published var distanceTraveled: Double = 0
    @Published var paceString: String = "0:00 / km"
    
    private var locationManager: CLLocationManager?
    private var timer: Timer?
    private var startLocation: CLLocation?
    private var lastLocation: CLLocation?
    
    override init() {
        super.init()
        // Initialize the location manager.
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        // Start updating location.
        locationManager?.startUpdatingLocation()
    }
    
    // MARK: - Run Control Methods
    
    func startRun() {
        // Reset stats.
        elapsedTime = 0
        distanceTraveled = 0
        paceString = "0:00 / km"
        startLocation = nil
        lastLocation = nil
        
        // Start updating location.
        locationManager?.startUpdatingLocation()
        
        // Start a timer to update elapsed time.
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
            self.updatePace()
        })
    }
    
    func pauseRun() {
        locationManager?.stopUpdatingLocation()
        timer?.invalidate()
    }
    
    func resumeRun() {
        locationManager?.startUpdatingLocation()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
            self.updatePace()
        })
    }
    
    func stopRun() {
        locationManager?.stopUpdatingLocation()
        timer?.invalidate()
    }
    
    // MARK: - Pace Calculation
    func updatePace() {
        guard distanceTraveled > 10 else {
            DispatchQueue.main.async {
                self.paceString = "0:00 / km"
            }
            return
        }
        let pace = elapsedTime / (distanceTraveled / 1000.0)
        let minutes = Int(pace / 60)
        let seconds = Int(pace) % 60
        DispatchQueue.main.async {
            self.paceString = String(format: "%d:%02d / km", minutes, seconds)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("Location updated: \(location.coordinate)") // Debug print
        // Skip low–accuracy updates.
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 else { return }
        
        if startLocation == nil {
            startLocation = location
        }
        if let last = lastLocation {
            let delta = location.distance(from: last)
            // Only count movements greater than 1 meter.
            if delta > 1.0 {
                distanceTraveled += delta
            }
        }
        lastLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location authorized")
        case .denied, .restricted:
            print("Location access denied/restricted")
        case .notDetermined:
            print("Location not determined")
        @unknown default:
            print("Unknown authorization status")
        }
    }
    
    // MARK: - Data Delegation
    // Since Firestore is not available on watchOS,
    // delegate upload to your iOS app using WatchConnectivity.
    #if os(watchOS)
    func uploadRunData(withCaption caption: String, footwear: String) {
        let runData: [String: Any] = [
            "distanceTraveled": distanceTraveled,
            "elapsedTime": elapsedTime,
            "timestamp": Date().timeIntervalSince1970,
            "caption": caption,
            "footwear": footwear
        ]
        WCSession.default.transferUserInfo(runData)
            print("Run data transferred via user info")
        
     //   let session = WCSession.default
     //   print("isReachable: \(session.isReachable)")
      //  if session.isReachable {
      //      session.sendMessage(runData, replyHandler: { reply in
       //         print("Run data sent to iOS: \(reply)")
       //     }, errorHandler: { error in
        //        print("Error sending run data: \(error.localizedDescription)")
        //    })
        //} else {
        //    print("iOS app not reachable via WCSession.")
      //  }
    }

    #endif
}

struct MinimalRunView: View {
    @StateObject var runTracker = MinimalRunTracker()
    // This state tracks if the run has been stopped.
    @State private var isStopped = false
    // Optional state for a caption and footwear. Modify as needed.
    @State private var caption = ""
    @State private var footwear = "Default Shoes"
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Run Stats")
                .font(.headline)
            Text("Distance: \(String(format: "%.2f", runTracker.distanceTraveled)) m")
            Text("Pace: \(runTracker.paceString)")
            Text("Time: \(formatTime(runTracker.elapsedTime))")
            HStack {
                Button("Start") {
                    isStopped = false
                    runTracker.startRun()
                }
                Button("Pause") {
                    runTracker.pauseRun()
                }
                Button("Stop") {
                    runTracker.stopRun()
                    // Show the upload button after stopping.
                    isStopped = true
                }
            }
            
            if isStopped {
                VStack(spacing: 5) {
                    TextField("Enter caption", text: $caption)
                        .textFieldStyle(PlainTextFieldStyle())
                    Button("Upload") {
                        // Call the upload method with entered caption and footwear.
                        runTracker.uploadRunData(withCaption: caption, footwear: footwear)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.top, 10)
            }
        }
        .padding()
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    MinimalRunView()
}
