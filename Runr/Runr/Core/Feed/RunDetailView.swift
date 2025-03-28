//
//  RunDetailView.swift
//  Runr
//
//  Created by Noah Moran on 13/3/2025.
//

import SwiftUI
import MapKit
import HealthKit

struct RunDetailView: View {
    // MARK: - Properties
    var post: Post?
    var run: RunData?
    var userId: String?
    @State private var timedLocations: [TimedLocation] = []
    @State private var splits: [Split] = []
    @State private var paceData: [PaceData] = []
    
    // HealthKit
    let healthManager = HealthKitManager.shared
    @State private var stepCount: Double = 0
    @State private var caloriesBurned: Double?
    
    // MARK: - Initializers
    init(post: Post) {
        self.post = post
        self.run = post.runData
        self.userId = post.ownerUid
    }
    
    init(run: RunData, userId: String) {
        self.run = run
        self.userId = userId
    }
    
    /// Fetch steps in a given time range
    func fetchSteps(startDate: Date, endDate: Date, completion: @escaping (Double) -> Void) {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepsType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
            guard let stats = stats,
                  let sum = stats.sumQuantity() else {
                completion(0)
                return
            }
            let steps = sum.doubleValue(for: HKUnit.count())
            completion(steps)
        }
        // Use the manager's healthStore
        healthManager.healthStore.execute(query)
    }
    
    // Fetch calories burned during a run for a user
    func fetchCaloriesBurned(startDate: Date, endDate: Date, completion: @escaping (Double?, Error?) -> Void) {
        guard let energyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil, nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: energyBurnedType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, error)
                return
            }
            // Convert from joules to kilocalories
            let kilocalories = sum.doubleValue(for: HKUnit.kilocalorie())
            completion(kilocalories, nil)
        }
        
        healthManager.healthStore.execute(query)
    }

    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // MARK: Top portion (User info, stats, and map) with a white background
                if let runData = run {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // MARK: User info
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(post?.user.username ?? "Unknown User")
                                    .font(.system(size: 16, weight: .bold))
                                
                                Text(timeAgoSinceDate(post?.timestamp ?? Date()))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 12)
                        
                        // MARK: Distance, Time, Pace
                        if let runData = post?.runData {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Distance")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("\(String(format: "%.2f km", runData.distance / 1000))")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    Spacer()
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Time")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        let timeMinutes = Int(runData.elapsedTime) / 60
                                        let timeSeconds = Int(runData.elapsedTime) % 60
                                        Text("\(String(format: "%d min %02d sec", timeMinutes, timeSeconds))")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    Spacer()
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Pace")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        let paceInSecondsPerKm = runData.elapsedTime / (runData.distance / 1000)
                                        let paceMinutes = Int(paceInSecondsPerKm) / 60
                                        let paceSeconds = Int(paceInSecondsPerKm) % 60
                                        Text("\(String(format: "%d:%02d / km", paceMinutes, paceSeconds))")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 4)
                        }
                        
                        // MARK: Map
                        if let runData = post?.runData, !runData.routeCoordinates.isEmpty {
                            RouteMapView(routeCoordinates: runData.routeCoordinates)
                                .frame(height: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.top, 6)
                                .allowsHitTesting(false) // Disable interaction on the map
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white) // <— White background for top section
                }
                
                // MARK: Additional Stats
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Additional Stats")
                                    .font(.headline)
                                
                                HStack {
                                    Text("Steps")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(Int(stepCount))")
                                }
                                HStack {
                                    Text("Calories Burned")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(Int(caloriesBurned ?? 0))")
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                            .padding(.top, 16)
                            

                // MARK: Splits Section
                if !splits.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Splits")
                            .font(.headline)
                        
                        // The bar chart for splits
                        SplitBarChartView(splits: splits)
                            .frame(height: 200)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 16)
                }

                // MARK: Pace Chart
                if !paceData.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pace Over Distance")
                            .font(.headline)
                        
                        // The line/area chart for pace
                        PaceLineChartView(paceData: paceData)
                            .frame(height: 200)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 16)
                }


                        }
                    }
                    .background(Color(.systemGroupedBackground).ignoresSafeArea())
                    .onAppear {
                        if let run = run {
                            let startDate = run.date
                            let endDate = run.date.addingTimeInterval(run.elapsedTime)
                            
                            // 1) Fetch Steps
                            fetchSteps(startDate: startDate, endDate: endDate) { fetchedSteps in
                                DispatchQueue.main.async {
                                    self.stepCount = fetchedSteps
                                }
                            }
                            
                            // 2) Fetch Calories
                            fetchCaloriesBurned(startDate: startDate, endDate: endDate) { kcal, error in
                                if let kcal = kcal {
                                    DispatchQueue.main.async {
                                        self.caloriesBurned = kcal
                                    }
                                }
                            }
                            
                            // 3) Compute splits
                            // If you don't have actual timedLocations, you can create approximations
                            if timedLocations.isEmpty, !run.routeCoordinates.isEmpty {
                                let totalPoints = run.routeCoordinates.count
                                timedLocations = run.routeCoordinates.enumerated().map { index, coordinate in
                                    let approxTime = run.date.addingTimeInterval((Double(index) / Double(totalPoints - 1)) * run.elapsedTime)
                                    return TimedLocation(coordinate: coordinate, timestamp: approxTime)
                                }
                            }
                            // Compute splits using your function (make sure you have defined computeKilometerSplits)
                            splits = computeKilometerSplits(from: timedLocations)
                            
                                    
                            // 2) Pace chart data
                            paceData = createPaceData(from: timedLocations)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
    
    // MARK: - Helper
    func timeAgoSinceDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    RunDetailView(post: Post.MOCK_POSTS[0])
}

