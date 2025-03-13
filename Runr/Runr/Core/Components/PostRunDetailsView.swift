//
//  PostRunDetailsView.swift
//  Runr
//
//  Created by Noah Moran on 13/3/2025.
//

import SwiftUI
import CoreLocation

struct PostRunDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var runTracker: RunTracker

    var routeCoordinates: [CLLocationCoordinate2D]
    var distance: Double
    var elapsedTime: Double
    var pace: String

    @State private var caption: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Post Your Run")
                    .font(.system(size: 28, weight: .bold))

                // Map preview
                RouteMapView(routeCoordinates: routeCoordinates)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Run stats
                HStack {
                    runStatView(title: "Distance", value: "\(String(format: "%.2f", distance)) km")
                    Spacer()
                    runStatView(title: "Time", value: "\(Int(elapsedTime) / 60) min \(Int(elapsedTime) % 60) sec")
                    Spacer()
                    runStatView(title: "Pace", value: pace)
                }
                .padding(.horizontal, 20)

                // Caption input field
                TextField("Write a caption...", text: $caption)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)

                Spacer()

                // Post button
                Button(action: {
                    Task {
                        await runTracker.uploadRunData(withCaption: caption)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Post Run")
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
                .padding(.bottom, 30)
            }
            .padding(.top, 20)
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
    PostRunDetailsView(routeCoordinates: [], distance: 5.0, elapsedTime: 600, pace: "5:00 / km")
        .environmentObject(RunTracker())
}
