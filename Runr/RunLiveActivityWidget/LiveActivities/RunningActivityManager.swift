//
//  RunningActivityManager.swift
//  Runr
//
//  Created by Noah Moran on 14/4/2025.
//

import ActivityKit
import Foundation

class RunningActivityManager {
    // This property holds the live activity instance.
    var activity: Activity<RunningActivityAttributes>?

    // Step 2: Starting a Live Activity
    func startActivity() {
        let initialContent = RunningActivityAttributes.ContentState(distance: 0.0, pace: 0.0, elapsedTime: 0)
        do {
            // Request a new live activity using your attributes.
            activity = try Activity<RunningActivityAttributes>.request(
                attributes: RunningActivityAttributes(),
                contentState: initialContent,
                pushType: nil   // Use nil if you're only relying on local updates.
            )
        } catch {
            print("Error starting live activity: \(error.localizedDescription)")
        }
    }

    // Step 3: Updating the Live Activity
    func updateActivity(distance: Double, pace: Double, elapsedTime: TimeInterval) {
        guard let runningActivity = activity else { return }
        Task {
            await runningActivity.update(using: RunningActivityAttributes.ContentState(distance: distance, pace: pace, elapsedTime: elapsedTime))
        }
    }

    // Step 4: Ending the Live Activity
    func endActivity() {
        guard let runningActivity = activity else { return }
        Task {
            await runningActivity.end(dismissalPolicy: .immediate)
        }
    }
}
