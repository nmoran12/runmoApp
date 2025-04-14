//
//  RunLiveActivityWidget.swift
//  RunLiveActivityWidget
//
//  Created by Noah Moran on 14/4/2025.
//

import WidgetKit
import ActivityKit
import SwiftUI

struct RunLiveActivityWidget: Widget {
    let kind: String = "RunLiveActivityWidget"
    
    // Helper function to format time consistently
    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        } else {
            return String(format: "%d s", secs)
        }
    }
    
    // Helper function to format pace with edge-case handling
    private func formatPace(distance: Double, time: Double) -> String {
        // If distance is less than 10 meters, show "--"
        guard distance > 10 else { return "--" }
        
        let distanceKm = distance / 1000.0
        let paceSecondsPerKm = time / distanceKm
        let paceMinutes = Int(paceSecondsPerKm / 60)
        let paceSeconds = Int(paceSecondsPerKm) % 60
        return "\(paceMinutes):\(String(format: "%02d", paceSeconds))/km"
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunningActivityAttributes.self) { context in
            
            // Outer ZStack lets us overlay "Runmo" at the top-left.
            ZStack(alignment: .topLeading) {
                // Your stats row inside an HStack, with extra padding on all sides
                HStack(spacing: 16) {
                    // Distance Column
                    VStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "figure.run")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("DISTANCE")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        let distanceKm = context.state.distance / 1000.0
                        Text("\(distanceKm, specifier: "%.2f") km")
                            .font(.title3)
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Vertical Divider
                    Divider()
                        .frame(height: 60)
                        .background(Color.gray.opacity(0.5))
                    
                    // Time Column
                    VStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "stopwatch")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("TIME")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(formatTime(context.state.elapsedTime))
                            .font(.title3)
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Vertical Divider
                    Divider()
                        .frame(height: 60)
                        .background(Color.gray.opacity(0.5))
                    
                    // Pace Column
                    VStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "speedometer")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("PACE")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(formatPace(distance: context.state.distance, time: context.state.elapsedTime))
                            .font(.title3)
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                }
                // Increase the padding around the entire stats row
                .padding(12)
                .background(Color.white)
                .cornerRadius(16)

                // "Runmo" overlay with its own padding
                Text("Runmo")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    // Adjust this padding to position the text further from the top/left edges
                    .padding(.top, 8)
                    .padding(.leading, 12)
            }

            // Expand the overall frame if needed.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .activityBackgroundTint(Color.white)
            .activitySystemActionForegroundColor(Color.black)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded state configuration for Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "figure.run")
                        .foregroundColor(.black)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    let distanceKm = context.state.distance / 1000.0
                    Text("\(distanceKm, specifier: "%.2f") km")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Time: \(formatTime(context.state.elapsedTime))")
                        .font(.footnote)
                        .foregroundColor(.black)
                }
            } compactLeading: {
                Image(systemName: "figure.run")
                    .foregroundColor(.black)
            } compactTrailing: {
                Text("\(Int(context.state.elapsedTime)) s")
                    .font(.subheadline)
                    .foregroundColor(.black)
            } minimal: {
                Image(systemName: "figure.run")
                    .foregroundColor(.black)
            }
        }
    }
}


// Create a pulsing animation effect for minimal Dynamic Island
struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                self.isPulsing = true
            }
    }
}
