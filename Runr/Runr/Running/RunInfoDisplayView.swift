//
//  RunInfoDisplayView.swift
//  Runr
//
//  Created by Noah Moran on 9/1/2025.
//

import SwiftUI
import CoreLocation

struct RunInfoDisplayView: View {
    var routeCoordinates: [CLLocationCoordinate2D]
    
    @EnvironmentObject var runTracker: RunTracker
    @Environment(\.presentationMode) var presentationMode
    var selectedFootwear: String
    
    var body: some View {
        ZStack {
            // Background gradient for subtle depth
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Title
                Text("Run")
                    .font(.system(size: 34, weight: .bold))
                    .padding(.top, 10)
                
                
                // Map displaying the route
                RouteMapView(routeCoordinates: routeCoordinates)
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Spacer()
                
                // Display run statistics
                HStack {
                    runStatView(title: "Distance", value: "\(String(format: "%.2f", runTracker.distanceTraveled / 1000)) km")
                    Spacer()
                    Spacer()
                    runStatView(title: "Time", value: "\(Int(runTracker.elapsedTime) / 60) min \(Int(runTracker.elapsedTime) % 60) sec")
                    Spacer()
                    Spacer()
                    runStatView(title: "Pace", value: "\(runTracker.paceString)")
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Finish Button
                NavigationLink(destination: PostRunDetailsView(
                    routeCoordinates: routeCoordinates,
                    distance: runTracker.distanceTraveled / 1000,
                    elapsedTime: runTracker.elapsedTime,
                    pace: runTracker.paceString,
                    footwear: selectedFootwear
                )) {

                    Text("Finish")
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 200, height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // Helper function for run statistics
    private func runStatView(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
        }
    }
}

#Preview {
    RunInfoDisplayView(routeCoordinates: [], selectedFootwear: "Adidas Predator")
        .environmentObject(RunTracker())
}


