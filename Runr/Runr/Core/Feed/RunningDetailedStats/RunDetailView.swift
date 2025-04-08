//
//  RunDetailView.swift
//  Runr
//
//  Created by Noah Moran on 13/3/2025.
//

import SwiftUI
import MapKit
import HealthKit
import Foundation

struct HeartRateDataPoint: Identifiable {
    let id = UUID()
    let time: Date
    let bpm: Double
}


struct RunDetailView: View {
    // MARK: - Properties
    var post: Post?
    var run: RunData?
    var userId: String?
    @State private var timedLocations: [TimedLocation] = []
    @State private var splits: [Split] = []
    @State private var paceData: [PaceData] = []
    
    // --- NEW: State for TE Score ---
        @State private var trainingEffectScore: Double = 0.0
    
    // --- NEW: Placeholder User Data for TE Calculation ---
        // Fetch these dynamically later from user profile/settings!
        let userRestingHR: Double = 65.0  // Example Resting HR
        let userMaxHR: Double = 190.0 // Example Max HR (e.g., 220 - age)
        let userGenderFactorB: Double = 1.92 // Example factor for male (1.67 for female)
    
    // HealthKit
    let healthManager = HealthKitManager.shared
    @State private var stepCount: Double = 0
    @State private var caloriesBurned: Double?
    
    // Heart Rate / Zones UI
    @State private var heartRateSamples: [HKQuantitySample] = []
    @State private var averageHR: Double = 0
    @State private var minHR: Double = 0
    @State private var maxHR: Double = 0
    @State private var heartRateZones: [HeartRateZone] = []

    
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
    
    // creating heart rate zones
    struct HeartRateZone {
        let name: String
        let lowerBound: Double
        let upperBound: Double
        var duration: TimeInterval // in seconds
        
        // Helper for a display string
        func durationString() -> String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // this is to generate fake heart rate data for now while i dont have the app set up fully
    func generateMockHeartRateSamples(startDate: Date, duration: TimeInterval) -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = []
        
        // Define the total number of samples you want (e.g., one sample every 1 second)
        let sampleInterval: TimeInterval = 1
        let numberOfSamples = Int(duration / sampleInterval)
        
        // Create a heart rate quantity type
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return samples }
        
        // Loop and create fake samples
        for i in 0..<numberOfSamples {
            // Simulate a heart rate value between 90 and 180 BPM
            let simulatedBPM = Double.random(in: 114...171)
            let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: simulatedBPM)
            
            // Create start and end dates for each sample
            let sampleStartDate = startDate.addingTimeInterval(Double(i) * sampleInterval)
            let sampleEndDate = sampleStartDate.addingTimeInterval(sampleInterval)
            
            let sample = HKQuantitySample(type: heartRateType,
                                          quantity: quantity,
                                          start: sampleStartDate,
                                          end: sampleEndDate)
            samples.append(sample)
        }
        
        return samples
    }
    
    func colorForZone(_ zone: HeartRateZone) -> Color {
        switch zone.name {
        case "Zone 1": return Color.blue
        case "Zone 2": return Color.green
        case "Zone 3": return Color.yellow
        case "Zone 4": return Color.orange
        case "Zone 5": return Color.red
        default:       return Color.gray
        }
    }
    
    

    // at the moment age is hard-coded, however eventually we must get the age data from user's and do this dynamically
    func processHeartRateSamples(_ samples: [HKQuantitySample], age: Int = 30) -> (averageHR: Double,
              minHR: Double,
              maxHR: Double,
              zones: [HeartRateZone])
    {
        guard !samples.isEmpty else {
            // Return empty or zero-based defaults
            let emptyZones = createZonesForAge(age)
            return (0, 0, 0, emptyZones)
        }
        
        let maxHR = Double(220 - age)
        var totalHR: Double = 0
        var totalCount: Double = 0
        
        // Create the 5 zones
        var zones = createZonesForAge(age)
        
        var overallMinHR = Double.greatestFiniteMagnitude
        var overallMaxHR = 0.0
        
        for sample in samples {
            // Heart rate is stored in "count/min" (BPM)
            let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            
            // Update min/max
            if bpm < overallMinHR { overallMinHR = bpm }
            if bpm > overallMaxHR { overallMaxHR = bpm }
            
            // Accumulate for average
            totalHR += bpm
            totalCount += 1
            
            // Determine how long this sample was "active"
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            
            // Find which zone it belongs to
            for i in zones.indices {
                if bpm >= zones[i].lowerBound && bpm < zones[i].upperBound {
                    zones[i].duration += duration
                    break
                }
            }
        }
        
        let avgHR = totalHR / totalCount
        return (avgHR, overallMinHR, overallMaxHR, zones)
    }

    /// Helper: Create the 5 zones based on the user's MHR
    func createZonesForAge(_ age: Int) -> [HeartRateZone] {
        let maxHR = Double(220 - age)
        
        // Define zone boundaries (in BPM)
        // For example:
        // Zone 1: 50–60%
        // Zone 2: 60–70%
        // Zone 3: 70–80%
        // Zone 4: 80–90%
        // Zone 5: 90–100%
        
        return [
            HeartRateZone(name: "Zone 1", lowerBound: 0.50 * maxHR, upperBound: 0.60 * maxHR, duration: 0),
            HeartRateZone(name: "Zone 2", lowerBound: 0.60 * maxHR, upperBound: 0.70 * maxHR, duration: 0),
            HeartRateZone(name: "Zone 3", lowerBound: 0.70 * maxHR, upperBound: 0.80 * maxHR, duration: 0),
            HeartRateZone(name: "Zone 4", lowerBound: 0.80 * maxHR, upperBound: 0.90 * maxHR, duration: 0),
            HeartRateZone(name: "Zone 5", lowerBound: 0.90 * maxHR, upperBound: 1.00 * maxHR + 1, duration: 0)
        ]
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
                        if !timedLocations.isEmpty {
                            DetailedMapView(timedLocations: timedLocations)
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
                
                // --- !!! NEW: Training Effect Card !!! ---
                            if trainingEffectScore > 0 { // Only display if score is calculated
                                TrainingEffectCard(teScore: trainingEffectScore)
                            }
                            // --- !!! END NEW SECTION !!! ---
                            

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
                
                // In RunDetailView body, after the other sections:

                // Always display Heart Rate section
                VStack(alignment: .leading, spacing: 16) {
                    // Heart Rate Title and Stats
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heart Rate")
                            .font(.headline)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Avg: \(Int(averageHR)) BPM")
                                    .font(.subheadline)
                                Text("Min: \(Int(minHR))   Max: \(Int(maxHR)) BPM")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                    }
                    
                    // Heart Rate Chart remains unchanged
                    let heartRateDataPoints = heartRateSamples.map { sample in
                        HeartRateDataPoint(
                            time: sample.startDate,
                            bpm: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                        )
                    }
                    HeartRateChartView(dataPoints: heartRateDataPoints, zoneForBPM: { bpm in
                        // Iterate over your precomputed heart rate zones to determine the zone name.
                        for zone in heartRateZones {
                            if bpm >= zone.lowerBound && bpm < zone.upperBound {
                                return zone.name
                            }
                        }
                        return "Zone 1" // Default to Zone 1 if no match found.
                    })
                    
                    // Heart Rate Zones Section
                    Text("Heart Rate Zones")
                        .font(.headline)
                    
                    let totalZoneDuration = heartRateZones.reduce(0) { $0 + $1.duration }
                    ForEach(heartRateZones, id: \.name) { zone in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(zone.name)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(colorForZone(zone))
                                    .cornerRadius(4)
                                
                                Spacer()
                                
                                Text("\(Int(zone.lowerBound))-\(Int(zone.upperBound)) BPM")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(zone.durationString())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(colorForZone(zone))
                                        .frame(width: geometry.size.width * CGFloat(totalZoneDuration > 0 ? zone.duration / totalZoneDuration : 0), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top, 16)



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
                
                
                // Elevation Graph View
                if !timedLocations.isEmpty {
                    ElevationView(locations: timedLocations)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        .padding(.top, 16)
                }



                        }
                    }
                    .background(Color.white.ignoresSafeArea(edges: .top))

                    .onAppear {
                        if let run = run {
                            let startDate = run.date
                            let endDate = run.date.addingTimeInterval(run.elapsedTime)
                            
                    // Use this for simulating heart rate samples instead of fetching from HealthKit
                            let simulatedSamples = generateMockHeartRateSamples(startDate: startDate, duration: run.elapsedTime)
                                    self.heartRateSamples = simulatedSamples
                                    let results = processHeartRateSamples(simulatedSamples, age: 30) // placeholder age
                                    self.averageHR = results.averageHR
                                    self.minHR = results.minHR
                                    self.maxHR = results.maxHR
                                    self.heartRateZones = results.zones

                                    // --- !!! ADD TE CALCULATION HERE for simulated data !!! ---
                                    calculateTrainingEffect(runData: run, avgHR: self.averageHR)
                                    // --- !!! END TE CALCULATION !!! ---
                            
                            // Fetch Steps
                            fetchSteps(startDate: startDate, endDate: endDate) { fetchedSteps in
                                DispatchQueue.main.async {
                                    self.stepCount = fetchedSteps
                                }
                            }
                            
                            // Fetch Calories
                            fetchCaloriesBurned(startDate: startDate, endDate: endDate) { kcal, error in
                                if let kcal = kcal {
                                    DispatchQueue.main.async {
                                        self.caloriesBurned = kcal
                                    }
                                }
                            }
                            
                            // fetch average heart rate
                            healthManager.fetchAverageHeartRate(
                              startDate: startDate,
                              endDate:   endDate
                            ) { avgBPM, error in
                              guard let bpm = avgBPM, error == nil else {
                                print("Avg HR error:", error ?? "unknown")
                                return
                              }
                              DispatchQueue.main.async {
                                self.averageHR = bpm
                              }
                            }
                            
                                // Fetch Heart Rate
                                healthManager.fetchHeartRateData(startDate: startDate, endDate: endDate) { samples, error in
                                    guard let samples = samples, error == nil else {
                                        print("Error fetching heart rate: \(String(describing: error))")
                                        return
                                    }
                                    
                                    DispatchQueue.main.async {
                                        self.heartRateSamples = samples
                                        let results = processHeartRateSamples(samples, age: 30) // placeholder age
                                        self.averageHR = results.averageHR
                                        self.minHR = results.minHR
                                        self.maxHR = results.maxHR
                                        self.heartRateZones = results.zones
                                    }
                                }
                            
                            // Compute splits
                            // If you don't have actual timedLocations, you can create approximations
                            if timedLocations.isEmpty, !run.routeCoordinates.isEmpty {
                                let totalPoints = run.routeCoordinates.count
                                timedLocations = run.routeCoordinates.enumerated().map { index, coordinate in
                                    let approxTime = run.date.addingTimeInterval((Double(index) / Double(totalPoints - 1)) * run.elapsedTime)
                                    
                                    // ALTITUDE IS JUST SIMULATED HERE WHEN YOU ACTUALLY IMPLEMENT IT CHANGE THIS
                                    let altitude = 50 + 10 * sin((Double(index) / Double(totalPoints)) * 2 * .pi)
                                    return TimedLocation(coordinate: coordinate,
                                                         timestamp: approxTime,
                                                         altitude: altitude)

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
    
    // --- NEW: Helper function to calculate TE ---
    private func calculateTrainingEffect(runData: RunData, avgHR: Double) {
        // Ensure we have valid inputs before calculating
        guard avgHR > 0, runData.elapsedTime > 0 else {
            print("DEBUG: Skipping TE calculation due to invalid avgHR or elapsedTime.")
            self.trainingEffectScore = 0.0 // Reset score if inputs invalid
            return
        }

        let calculator = TrainingEffectCalculator(
            hrRest: userRestingHR,
            hrMax: userMaxHR,
            b: userGenderFactorB
        )
        let durationMinutes = runData.elapsedTime / 60.0
        let trimp = calculator.computeTRIMP(avgHR: avgHR, durationMinutes: durationMinutes)
        let teScore = calculator.trainingEffect(from: trimp)

        // Update the state variable on the main thread
        DispatchQueue.main.async {
            self.trainingEffectScore = teScore
            print("DEBUG: Calculated Training Effect Score: \(teScore)") // Verify calculation
        }
    }
}

#Preview {
    RunDetailView(post: Post.MOCK_POSTS[0])
}

