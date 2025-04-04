//
//  BestEffortsViewModel.swift
//  Runr
//
//  Created by Noah Moran on 4/4/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class BestEffortsViewModel: ObservableObject {
    @Published var bestEfforts: [BestEffort] = []
    
    // Updated BestEffort to include a date property.
    struct BestEffort: Identifiable {
        var id = UUID()
        let distance: String  // e.g., "5K", "10K", etc.
        let time: Double      // Best time in seconds
        let date: Date?       // Date of the fastest run
    }
    
    // Updated generic function that fetches fastest equivalent time along with its run date.
    private func fetchFastestTime(for targetDistance: Double,
                                  userId: String,
                                  completion: @escaping ((Double, Date)?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("runs")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("DEBUG: Error fetching runs for user \(userId): \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    completion(nil)
                    return
                }
                
                var fastestTime: Double? = nil
                var fastestDate: Date? = nil
                for doc in docs {
                    let data = doc.data()
                    // Ensure the run meets the target distance and get the run's date.
                    guard let distance = data["distance"] as? Double,
                          let elapsedTime = data["elapsedTime"] as? Double,
                          let timestamp = data["date"] as? Timestamp,
                          distance >= targetDistance else { continue }
                    
                    let runDate = timestamp.dateValue()
                    let equivalentTime = elapsedTime * (targetDistance / distance)
                    
                    if let currentFastest = fastestTime {
                        if equivalentTime < currentFastest {
                            fastestTime = equivalentTime
                            fastestDate = runDate
                        }
                    } else {
                        fastestTime = equivalentTime
                        fastestDate = runDate
                    }
                }
                
                if let fastestTime = fastestTime, let fastestDate = fastestDate {
                    completion((fastestTime, fastestDate))
                } else {
                    completion(nil)
                }
            }
    }
    
    // Updated loadPersonalBests uses the new fetch function.
    func loadPersonalBests() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No current user found.")
            return
        }
        
        // Define the events with target distances and display labels.
        let events: [(eventKey: String, label: String, targetDistance: Double)] = [
            ("fastest5k", "5K", 5000.0),
            ("fastest10k", "10K", 10000.0),
            ("fastestHalfMarathon", "Half Marathon", 21097.5),
            ("fastestMarathon", "Marathon", 42195.0)
        ]
        
        let group = DispatchGroup()
        var efforts: [BestEffort] = []
        
        for event in events {
            group.enter()
            fetchFastestTime(for: event.targetDistance, userId: userId) { result in
                if let result = result {
                    let (fastest, runDate) = result
                    efforts.append(BestEffort(distance: event.label, time: fastest, date: runDate))
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Sort efforts in a defined order.
            let desiredOrder = ["5K", "10K", "Half Marathon", "Marathon"]
            efforts.sort { a, b in
                guard let indexA = desiredOrder.firstIndex(of: a.distance),
                      let indexB = desiredOrder.firstIndex(of: b.distance) else { return false }
                return indexA < indexB
            }
            withAnimation {
                self.bestEfforts = efforts
            }
        }
    }
    
    // Convert time in seconds to a formatted string (mm:ss or h:mm:ss).
    func formattedTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}


