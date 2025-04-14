//
//  WatchConnectivityManager.swift
//  RunmoWatchApp Watch App
//
//  Created by Noah Moran on 9/4/2025.
//

#if os(watchOS)
import WatchConnectivity
import Foundation

class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - WCSessionDelegate Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Implement handling messages from the iOS app if needed.
        print("Received message from iOS: \(message)")
    }
    
    // Other WCSessionDelegate methods can be added here if required.
}
#endif
