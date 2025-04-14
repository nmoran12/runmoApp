//
//  ContentView.swift
//  RunmoWatchApp Watch App
//
//  Created by Noah Moran on 9/4/2025.
//

#if os(watchOS)
import SwiftUI

struct ContentView: View {
    // Replace these with real-time data updates from your workout session.
    @State private var time: String = "00:00:00"
    @State private var distance: String = "0.0 mi"
    @State private var pace: String = "0:00 /mi"
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some View {
        MinimalRunView()
    }
}

#Preview {
    ContentView()
}
#endif
