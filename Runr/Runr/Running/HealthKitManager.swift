//
//  HealthKitManager.swift
//  Runr
//
//  Created by Noah Moran on 23/3/2025.
//

import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    private init() {}
    
    // Types you want to read
        let readTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            // .heartRate, .distanceWalkingRunning, etc. if needed
        ]
    
    // Example function to request authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }

        // Define the data types you want to read
        guard
            let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
            let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount),
            let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        else {
            completion(false, nil)
            return
        }

        // If you only need read access, use toShare: []
        let typesToRead: Set<HKObjectType> = [heartRateType, stepsType, activeEnergyType]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            completion(success, error)
        }
        
        
    }
    
    
    
    // MARK: - Fetch Heart Rate Samples
        /// Fetch heart rate samples in the given date range
        func fetchHeartRateData(startDate: Date,
                                endDate: Date,
                                completion: @escaping ([HKQuantitySample]?, Error?) -> Void)
        {
            guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                completion(nil, nil)
                return
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                        end: endDate,
                                                        options: .strictStartDate)
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            
            let query = HKSampleQuery(sampleType: heartRateType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sortDescriptor]) { _, samples, error in
                
                guard error == nil else {
                    completion(nil, error)
                    return
                }
                
                // Cast samples to HKQuantitySample
                let hrSamples = samples as? [HKQuantitySample]
                completion(hrSamples, nil)
            }
            
            healthStore.execute(query)
        }
    
    // MARK: - Fetch Average Heart Rate
        /// Fetches the average heart rate (in bpm) between the given dates.
        func fetchAverageHeartRate(startDate: Date,
                                   endDate: Date,
                                   completion: @escaping (Double?, Error?) -> Void)
        {
            guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                completion(nil, nil)
                return
            }

            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let statsQuery = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                guard let avgQuantity = result?.averageQuantity() else {
                    completion(nil, error)
                    return
                }
                let bpm = avgQuantity.doubleValue(
                    for: HKUnit.count().unitDivided(by: HKUnit.minute())
                )
                completion(bpm, nil)
            }

            healthStore.execute(statsQuery)
        }

    
    // MARK: - Average Heart Rate
        /// Fetches the average heart rate for a given workout
        func fetchAverageHeartRate(for workout: HKWorkout,
                                   completion: @escaping (Double?) -> Void) {
            guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
                completion(nil)
                return
            }

            let predicate = HKQuery.predicateForObjects(from: workout)
            let statsQuery = HKStatisticsQuery(quantityType: hrType,
                                               quantitySamplePredicate: predicate,
                                               options: .discreteAverage) { _, result, error in
                guard let avgQuantity = result?.averageQuantity() else {
                    completion(nil)
                    return
                }
                let bpm = avgQuantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                completion(bpm)
            }

            healthStore.execute(statsQuery)
        }
    }

