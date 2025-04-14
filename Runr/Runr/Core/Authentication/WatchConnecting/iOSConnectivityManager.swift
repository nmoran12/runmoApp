//
//  iOSConnectivityManager.swift
//  Runr
//
//  Created by Noah Moran on 10/4/2025.
//

import WatchConnectivity

class iOSConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = iOSConnectivityManager()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // Process incoming messages from the watch.
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Received run data from watch: \(message)")
        // Handle the run data here – e.g., upload to Firestore.
        replyHandler(["status": "received"])
    }
    
    // Already implemented:
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        print("iOS received run data via user info: \(userInfo)")
        // Process and upload data here.
    }
    
    // Required methods:
    func sessionDidBecomeInactive(_ session: WCSession) {
        // You can leave this empty or perform any necessary cleanup.
        print("WCSession did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Typically, you would reactivate the session.
        print("WCSession did deactivate")
        WCSession.default.activate()
    }
    
}
