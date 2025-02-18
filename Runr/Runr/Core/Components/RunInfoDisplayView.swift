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
    
    var body: some View {
        VStack {
            Text("Run")
                .font(.system(size: 34, weight: .bold))
                .padding(.top, 10)
            
            Spacer()
            
            // Map displaying the route
            RouteMapView(routeCoordinates: routeCoordinates)
                .frame(height: 300)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.horizontal)

            Spacer()
            
            // Display run statistics
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Distance")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(runTracker.distanceTraveled / 1000, specifier: "%.2f") km")
                        .font(.system(size: 22, weight: .semibold))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 5) {
                    Text("Time")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(Int(runTracker.elapsedTime) / 60) min \(Int(runTracker.elapsedTime) % 60) sec")
                        .font(.system(size: 22, weight: .semibold))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 5) {
                    Text("Pace")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(runTracker.paceString)")
                        .font(.system(size: 22, weight: .semibold))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            
            Spacer()
            
            // Finish Button
            Button(action: {
                Task {
                    await runTracker.uploadRunData()
                    print("Upload button is working")
                    
                    presentationMode.wrappedValue.dismiss() // Navigate back
                }
            }) {
                Text("Finish")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
            }
            .padding(.bottom, 20)
        }
    }
}


#Preview {
    RunInfoDisplayView(routeCoordinates: [])
        .environmentObject(RunTracker())
}

