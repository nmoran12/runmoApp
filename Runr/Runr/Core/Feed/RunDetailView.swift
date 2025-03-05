//
//  RunDetailView.swift
//  Runr
//
//  Created by Noah Moran on 21/2/2025.
//

import SwiftUI
import MapKit

struct RunDetailView: View {
    var post: Post?
    var run: RunData?
    var userId: String?

    init(post: Post) {
        self.post = post
        self.run = post.runData
        self.userId = post.ownerUid
    }

    init(run: RunData, userId: String) {
        self.run = run
        self.userId = userId
    }

    var body: some View {
        VStack {
            Text("\(post?.user.username ?? "Run Details")")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Distance:")
                        .font(.headline)
                    Spacer()
                    Text("\(String(format: "%.2f km", run?.distance ?? 0.0))")
                }

                HStack {
                    Text("Time:")
                        .font(.headline)
                    Spacer()
                    let timeMinutes = Int(run?.elapsedTime ?? 0) / 60
                    let timeSeconds = Int(run?.elapsedTime ?? 0) % 60
                    Text("\(String(format: "%d min %02d sec", timeMinutes, timeSeconds))")
                }

                HStack {
                    Text("Pace:")
                        .font(.headline)
                    Spacer()
                    if let runData = run {
                        let paceInSecondsPerKm = runData.elapsedTime / (runData.distance / 1000)
                        let paceMinutes = Int(paceInSecondsPerKm) / 60
                        let paceSeconds = Int(paceInSecondsPerKm) % 60
                        Text("\(String(format: "%d:%02d / km", paceMinutes, paceSeconds))")
                    } else {
                        Text("N/A")
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            .padding()

            if let routeCoordinates = run?.routeCoordinates, !routeCoordinates.isEmpty {
                RouteMapView(routeCoordinates: routeCoordinates)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    RunDetailView(post: Post.MOCK_POSTS[0]) // Supports both Post and RunData
}
